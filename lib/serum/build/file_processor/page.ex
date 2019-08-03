defmodule Serum.Build.FileProcessor.Page do
  @moduledoc false

  import Serum.IOProxy, only: [put_msg: 2]
  alias Serum.Markdown
  alias Serum.Page
  alias Serum.Plugin
  alias Serum.Project
  alias Serum.Renderer
  alias Serum.Result
  alias Serum.Template
  alias Serum.Template.Compiler, as: TC

  @doc false
  @spec preprocess_pages([Serum.File.t()], Project.t()) :: Result.t({[Page.t()], [map()]})
  def preprocess_pages(files, proj) do
    put_msg(:info, "Processing page files...")

    result =
      files
      |> Task.async_stream(&preprocess_page(&1, proj))
      |> Enum.map(&elem(&1, 1))
      |> Result.aggregate_values(:file_processor)

    case result do
      {:ok, pages} ->
        sorted_pages = Enum.sort(pages, &(&1.order < &2.order))

        {:ok, {sorted_pages, Enum.map(sorted_pages, &Page.compact/1)}}

      {:error, _} = error ->
        error
    end
  end

  @spec preprocess_page(Serum.File.t(), Project.t()) :: Result.t(Page.t())
  defp preprocess_page(file, proj) do
    import Serum.HeaderParser

    opts = [
      title: :string,
      label: :string,
      group: :string,
      order: :integer,
      template: :string
    ]

    required = [:title]

    with {:ok, %{in_data: data} = file2} <- Plugin.processing_page(file),
         {:ok, {header, extras, rest}} <- parse_header(data, opts, required) do
      header = Map.put(header, :label, header[:label] || header.title)
      page = Page.new(file2.src, header, rest, proj)

      {:ok, %Page{page | extras: extras}}
    else
      {:invalid, message} -> {:error, {message, file.src, 0}}
      {:error, _} = plugin_error -> plugin_error
    end
  end

  @doc false
  @spec process_pages([Page.t()], map(), Project.t()) :: Result.t([Page.t()])
  def process_pages(pages, includes, proj) do
    pages
    |> Task.async_stream(&process_page(&1, includes, proj))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate_values(:file_processor)
    |> case do
      {:ok, pages} -> Plugin.processed_pages(pages)
      {:error, _} = error -> error
    end
  end

  @spec process_page(Page.t(), map(), Project.t()) :: Result.t(Page.t())
  defp process_page(page, includes, proj) do
    case do_process_page(page, includes, proj) do
      {:ok, page} -> Plugin.processed_page(page)
      {:error, _} = error -> error
    end
  end

  @spec do_process_page(Page.t(), map(), Project.t()) :: Result.t(Page.t())
  defp do_process_page(page, includes, proj)

  defp do_process_page(%Page{type: ".md"} = page, _includes, proj) do
    {:ok, %Page{page | data: Markdown.to_html(page.data, proj)}}
  end

  defp do_process_page(%Page{type: ".html"} = page, _includes, _proj) do
    {:ok, page}
  end

  defp do_process_page(%Page{type: ".html.eex"} = page, includes, _proj) do
    tc_options = [type: :template, includes: includes]

    with {:ok, ast} <- TC.compile_string(page.data, tc_options),
         template = Template.new(ast, :template, page.file),
         {:ok, html} <- Renderer.render_fragment(template, []) do
      {:ok, %Page{page | data: html}}
    else
      {:ct_error, msg, line} -> {:error, {msg, page.file, line}}
      {:error, _} = error -> error
    end
  end
end
