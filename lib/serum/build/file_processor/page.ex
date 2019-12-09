defmodule Serum.Build.FileProcessor.Page do
  @moduledoc false

  require Serum.Result, as: Result
  import Serum.IOProxy, only: [put_msg: 2]
  alias Serum.Error
  alias Serum.Markdown
  alias Serum.Page
  alias Serum.Plugin.Client, as: PluginClient
  alias Serum.Project
  alias Serum.Renderer
  alias Serum.Template
  alias Serum.Template.Compiler, as: TC

  @spec preprocess_pages([Serum.File.t()], Project.t()) :: Result.t({[Page.t()], [map()]})
  def preprocess_pages(files, proj) do
    put_msg(:info, "Processing page files...")

    files
    |> Task.async_stream(&preprocess_page(&1, proj))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate("failed to preprocess pages:")
    |> case do
      {:ok, pages} ->
        sorted_pages = Enum.sort(pages, &(&1.order < &2.order))

        Result.return({sorted_pages, Enum.map(sorted_pages, &Page.compact/1)})

      {:error, %Error{}} = error ->
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

    Result.run do
      %{in_data: data} = file2 <- PluginClient.processing_page(file)
      {header, extras, rest, _next_line} <- parse_header(data, opts, required)
      header = Map.put(header, :label, header[:label] || header.title)
      page = Page.new(file2.src, {header, extras}, rest, proj)

      Result.return(page)
    end
  end

  @spec process_pages([Page.t()], Project.t()) :: Result.t([Page.t()])
  def process_pages(pages, proj) do
    pages
    |> Task.async_stream(&process_page(&1, proj))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate("failed to process pages:")
    |> case do
      {:ok, pages} -> PluginClient.processed_pages(pages)
      {:error, %Error{}} = error -> error
    end
  end

  @spec process_page(Page.t(), Project.t()) :: Result.t(Page.t())
  defp process_page(page, proj) do
    case do_process_page(page, proj) do
      {:ok, page} -> PluginClient.processed_page(page)
      {:error, %Error{}} = error -> error
    end
  end

  @spec do_process_page(Page.t(), Project.t()) :: Result.t(Page.t())
  defp do_process_page(page, proj)

  defp do_process_page(%Page{type: ".md"} = page, proj) do
    Result.return(%Page{page | data: Markdown.to_html(page.data, proj)})
  end

  defp do_process_page(%Page{type: ".html"} = page, _proj) do
    Result.return(page)
  end

  defp do_process_page(%Page{type: ".html.eex"} = page, _proj) do
    Result.run do
      ast <- TC.compile_string(page.data)
      template = Template.new(ast, page.file, :template, page.file)
      new_template <- TC.Include.expand(template)
      html <- Renderer.render_fragment(new_template, [])

      Result.return(%Page{page | data: html})
    else
      {:ct_error, msg, line} ->
        Result.fail(Simple, [msg], file: %Serum.File{src: page.file}, line: line)

      {:error, %Error{}} = error ->
        error
    end
  end
end
