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
  alias Serum.HeaderParser
  alias Serum.PageInfo

  @type state :: Build.state

  @async_opt [max_concurrency: System.schedulers_online * 10]

  @doc "Starts the first pass of PageBuilder."
  @spec run(Build.mode, state) :: Error.result([PageInfo.t])

  def run(mode, state) do
    IO.puts "Collecting pages information..."
    page_dir = Path.join state.src, "pages"
    if File.exists? page_dir do
      files =
        [page_dir, "**", "*.{md,html,html.eex}"]
        |> Path.join()
        |> Path.wildcard()
      result = launch mode, files, state
      Error.filter_results_with_values result, :page_builder
    else
      {:error, {page_dir, :enoent, 0}}
    end
  end

  @spec launch(Build.mode, [binary], state) :: [Error.result(PageInfo.t)]

  defp launch(:parallel, files, state) do
    files
    |> Task.async_stream(__MODULE__, :page_task, [state], @async_opt)
    |> Enum.map(&(elem &1, 1))
  end

  defp launch(:sequential, files, state) do
    files |> Enum.map(&page_task(&1, state))
  end

  @doc false
  @spec page_task(binary, state) :: Error.result(PageInfo.t)

  def page_task(fname, state) do
    opts = [title: :string, label: :string, group: :string, order: :integer]
    reqs = [:title]
    with {:ok, file} <- File.open(fname, [:read, :utf8]),
         {:ok, header} <- HeaderParser.parse_header(file, fname, opts, reqs)
    do
      File.close file
      {:ok, PageInfo.new(fname, header, state)}
    else
      {:error, reason} when is_atom(reason) -> {:error, {reason, fname, 0}}
      {:error, _} = error -> error
    end
  end
end
