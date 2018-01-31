defmodule Serum.Build.Pass1.PageBuilder do
  @moduledoc """
  During pass 1, PageBuilder does the following:

  1. Recursively scan `/path/to/project/pages/` directory for any page source
    files. All files which name ends with `.md`, `.html` or `.html.eex` will be
    registered.
  2. Parses headers of all scanned page source files.
  3. Generates `Serum.PageInfo` objects for all pages and stores them for later
   use in the second pass.
  """

  alias Serum.Error
  alias Serum.Build
  alias Serum.Page

  @async_opt [max_concurrency: System.schedulers_online * 10]

  @doc "Starts the first pass of PageBuilder."
  @spec run(Build.mode, binary(), binary(), map()) :: Error.result([PageInfo.t])

  def run(mode, src, dest, proj) do
    IO.puts "Collecting pages information..."
    page_dir = src == "." && "pages" || Path.join(src, "pages")
    if File.exists? page_dir do
      files =
        [page_dir, "**", "*.{md,html,html.eex}"]
        |> Path.join()
        |> Path.wildcard()
      result = launch mode, files, src, dest, proj
      Error.filter_results_with_values result, :page_builder
    else
      {:error, {page_dir, :enoent, 0}}
    end
  end

  @spec launch(Build.mode, [binary], binary(), binary(), map())
    :: [Error.result(PageInfo.t)]
  defp launch(mode, files, src, dest, proj)

  defp launch(:parallel, files, src, dest, proj) do
    files
    |> Task.async_stream(Page, :load, [src, dest, proj], @async_opt)
    |> Enum.map(&(elem &1, 1))
  end

  defp launch(:sequential, files, src, dest, proj) do
    files |> Enum.map(&Page.load(&1, src, dest, proj))
  end
end
