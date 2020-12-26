defmodule Serum.Build.FileProcessor.Page do
  @moduledoc false

  require Serum.V2.Result, as: Result
  import Serum.V2.Console, only: [put_msg: 2]
  alias Serum.Build.FileProcessor.Content
  alias Serum.Plugin.Client, as: PluginClient
  alias Serum.V2
  alias Serum.V2.BuildContext
  alias Serum.V2.Error
  alias Serum.V2.Page

  @spec preprocess_pages([V2.File.t()], BuildContext.t()) :: Result.t({[Page.t()]})
  def preprocess_pages(files, context) do
    put_msg(:info, "Processing page files...")

    Result.run do
      files <- PluginClient.processing_pages(files)
      pages <- do_preprocess_pages(files, context)
      sorted_pages = Enum.sort(pages, &(&1.order < &2.order))

      Result.return(sorted_pages)
    end
  end

  @spec do_preprocess_pages([V2.File.t()], BuildContext.t()) :: Result.t([Page.t()])
  defp do_preprocess_pages(files, context) do
    files
    |> Task.async_stream(&preprocess_page(&1, context))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate("failed to preprocess pages:")
  end

  @spec preprocess_page(V2.File.t(), BuildContext.t()) :: Result.t(Page.t())
  defp preprocess_page(file, context) do
    import Serum.HeaderParser
    alias Serum.HeaderParser.ParseResult

    opts = [
      title: :string,
      label: :string,
      group: :string,
      order: :integer,
      template: :string
    ]

    Result.run do
      %ParseResult{} = header <- parse_header(file, opts, ~w(title)a)
      Result.return(Serum.Page.new(file, header, context))
    end
  end

  @spec process_pages([Page.t()], BuildContext.t()) :: Result.t([Page.t()])
  def process_pages(pages, context) do
    pages
    |> Task.async_stream(&process_page(&1, context))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate("failed to process pages:")
    |> case do
      {:ok, pages} -> PluginClient.processed_pages(pages)
      {:error, %Error{}} = error -> error
    end
  end

  @spec process_page(Page.t(), BuildContext.t()) :: Result.t(Page.t())
  defp process_page(page, context) do
    process_opts = [file: page.source, line: page.extras["__serum__next_line__"]]

    case Content.process_content(page.data, page.type, context, process_opts) do
      {:ok, data} -> Result.return(%Page{page | data: data})
      {:error, %Error{}} = error -> error
    end
  end
end
