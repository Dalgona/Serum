defmodule Serum.Build.FileProcessor.Page do
  @moduledoc false

  require Serum.Result, as: Result
  import Serum.V2.Console, only: [put_msg: 2]
  alias Serum.Build.FileProcessor.Content
  alias Serum.Error
  alias Serum.Page
  alias Serum.Plugin.Client, as: PluginClient
  alias Serum.Project

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
    process_opts = [file: page.file, line: page.extras[@next_line_key]]

    case Content.process_content(page.data, page.type, proj, process_opts) do
      {:ok, data} -> Result.return(%Page{page | data: data})
      {:error, %Error{}} = error -> error
    end
  end
end
