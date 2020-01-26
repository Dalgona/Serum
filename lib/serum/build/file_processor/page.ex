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

  @next_line_key "__serum__next_line__"

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
      file2 <- PluginClient.processing_page(file)
      {header, extras, rest, next_line} <- parse_header(file2, opts, required)
      header = Map.put(header, :label, header[:label] || header.title)
      page = Page.new(file2, {header, extras}, rest, proj)

      page = %Page{
        page
        | extras: Map.put(page.extras, @next_line_key, next_line)
      }

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
      {:ok, page} ->
        page = %Page{page | extras: Map.delete(page.extras, @next_line_key)}

        PluginClient.processed_page(page)

      {:error, %Error{}} = error ->
        error
    end
  end

  @spec do_process_page(Page.t(), Project.t()) :: Result.t(Page.t())
  defp do_process_page(page, proj)

  defp do_process_page(%Page{type: "md"} = page, proj) do
    Result.run do
      line = page.extras[@next_line_key] || 1
      ast <- TC.compile_string(page.data, line: line)
      template = Template.new(ast, page.file.src, :template, page.file)
      new_template <- TC.Include.expand(template)
      md <- Renderer.render_fragment(new_template, [])

      Result.return(%Page{page | data: Markdown.to_html(md, proj)})
    else
      {:ct_error, msg, line} ->
        Result.fail(Simple, [msg], file: page.file, line: line)

      {:error, %Error{}} = error ->
        error
    end
  end

  defp do_process_page(%Page{type: "html"} = page, _proj) do
    Result.run do
      line = page.extras[@next_line_key] || 1
      ast <- TC.compile_string(page.data, line: line)
      template = Template.new(ast, page.file.src, :template, page.file)
      new_template <- TC.Include.expand(template)
      html <- Renderer.render_fragment(new_template, [])

      Result.return(%Page{page | data: html})
    else
      {:ct_error, msg, line} ->
        Result.fail(Simple, [msg], file: page.file, line: line)

      {:error, %Error{}} = error ->
        error
    end
  end
end
