defmodule Serum.Build.FileProcessor.Page do
  @moduledoc false

  import Serum.IOProxy, only: [put_msg: 2]
  alias Serum.Markdown
  alias Serum.Page
  alias Serum.Plugin.Client, as: PluginClient
  alias Serum.Project
  alias Serum.Renderer
  alias Serum.Result
  alias Serum.Template
  alias Serum.Template.Compiler, as: TC

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

    with {:ok, %{in_data: data} = file2} <- PluginClient.processing_page(file),
         {:ok, {header, extras, rest}} <- parse_header(data, opts, required) do
      header = Map.put(header, :label, header[:label] || header.title)
      page = Page.new(file2.src, {header, extras}, rest, proj)

      {:ok, page}
    else
      {:invalid, message} -> {:error, {message, file.src, 0}}
      {:error, _} = plugin_error -> plugin_error
    end
  end

  @spec process_pages([Page.t()], Project.t()) :: Result.t([Page.t()])
  def process_pages(pages, proj) do
    pages
    |> Task.async_stream(&process_page(&1, proj))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate_values(:file_processor)
    |> case do
      {:ok, pages} -> PluginClient.processed_pages(pages)
      {:error, _} = error -> error
    end
  end

  @spec process_page(Page.t(), Project.t()) :: Result.t(Page.t())
  defp process_page(page, proj) do
    case do_process_page(page, proj) do
      {:ok, page} -> PluginClient.processed_page(page)
      {:error, _} = error -> error
    end
  end

  @spec do_process_page(Page.t(), Project.t()) :: Result.t(Page.t())
  defp do_process_page(page, proj)

  defp do_process_page(%Page{type: ".md"} = page, proj) do
    {:ok, %Page{page | data: Markdown.to_html(page.data, proj)}}
  end

  defp do_process_page(%Page{type: ".html"} = page, _proj) do
    {:ok, page}
  end

  defp do_process_page(%Page{type: ".html.eex"} = page, _proj) do
    with {:ok, ast} <- TC.compile_string(page.data),
         template = Template.new(ast, page.file, :template, page.file),
         {:ok, new_template} <- TC.Include.expand(template),
         {:ok, html} <- Renderer.render_fragment(new_template, []) do
      {:ok, %Page{page | data: html}}
    else
      {:ct_error, msg, line} -> {:error, {msg, page.file, line}}
      {:error, _} = error -> error
    end
  end
end
