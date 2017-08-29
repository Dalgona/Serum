defmodule Serum.Build.Pass1.PostBuilder do
  @moduledoc """
  During Pass1, PostBuilder does the following:

  1. Scans `/path/to/project/posts/` directory for any post source files. All
    files which name ends with `.md` will be loaded.
  2. Parses headers of all scanned post source files.
  3. Reads the contents of each post source file and converts to HTML using
    Earmark. And then generates the preview text from that HTML data.
  4. Generates `Serum.PostInfo` object for each post and stores them for later
    use in the second pass.
  """

  import Serum.Util
  alias Serum.Error
  alias Serum.Build
  alias Serum.HeaderParser
  alias Serum.PostInfo

  @type state :: Build.state
  @type erl_datetime :: {erl_date, erl_time}
  @type erl_date :: {non_neg_integer, non_neg_integer, non_neg_integer}
  @type erl_time :: {non_neg_integer, non_neg_integer, non_neg_integer}

  @async_opt [max_concurrency: System.schedulers_online * 10]

  @doc "Starts the first pass of PostBuilder."
  @spec run(Build.mode, state) :: Error.result([PostInfo.t])

  def run(mode, state) do
    IO.puts "Collecting posts information..."
    list = load_file_list Path.join(state.src, "posts")
    result = launch mode, list, state
    Error.filter_results_with_values result, :post_builder
  end

  @spec load_file_list(binary) :: [binary]

  defp load_file_list(srcdir) do
    case File.ls srcdir do
      {:ok, list} ->
        list
        |> Enum.filter(&String.ends_with?(&1, ".md"))
        |> Enum.map(&String.replace(&1, ~r/\.md$/, ""))
        |> Enum.sort
      {:error, _reason} ->
        warn "Cannot access `posts/'. No post will be generated."
        []
    end
  end

  @spec launch(Build.mode, [binary], state) :: [Error.result(PostInfo.t)]

  defp launch(:parallel, files, state) do
    files
    |> Task.async_stream(__MODULE__, :post_task, [state], @async_opt)
    |> Enum.map(&(elem &1, 1))
  end

  defp launch(:sequential, files, state) do
    files |> Enum.map(&post_task(&1, state))
  end

  @doc false
  @spec post_task(binary, state) :: Error.result(PostInfo.t)

  def post_task(file, state) do
    opts = [title: :string, tags: {:list, :string}, date: :datetime]
    reqs = [:title]
    filename = Path.join [state.src, "posts", file <> ".md"]
    with {:ok, file} <- File.open(filename, [:read, :utf8]),
         {:ok, header} <- HeaderParser.parse_header(file, filename, opts, reqs)
    do
      html = file |> IO.read(:all) |> Earmark.to_html
      File.close file
      info = PostInfo.new filename, header, html, state
      {:ok, info}
    else
      {:error, reason} when is_atom(reason) -> {:error, {reason, filename, 0}}
      {:error, _} = error -> error
    end
  end
end
