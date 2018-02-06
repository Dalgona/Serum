defmodule Serum.Build.Pass1.PostBuilder do
  @moduledoc """
  During Pass1, PostBuilder does the following:

  1. Scans `/path/to/project/posts/` directory for any post source files. All
    files which name ends with `.md` will be loaded.
  2. Parses headers of all scanned post source files.
  3. Reads the contents of each post source file and converts to HTML using
    Earmark. And then generates the preview text from that HTML data.
  4. Generates `Serum.Post` object for each post and stores them for later
    use in the second pass.
  """

  import Serum.Util
  alias Serum.Error
  alias Serum.Post

  @async_opt [max_concurrency: System.schedulers_online * 10]

  @doc "Starts the first pass of PostBuilder."
  @spec run(Build.mode, map()) :: Error.result([Post.t])

  def run(mode, proj) do
    files = load_file_list(proj.src)
    result = launch mode, files, proj
    Error.filter_results_with_values result, :post_builder
  end

  @spec load_file_list(binary()) :: [binary()]

  defp load_file_list(src) do
    IO.puts "Collecting posts information..."
    post_dir = src == "." && "posts" || Path.join(src, "posts")
    if File.exists?(post_dir) do
      [post_dir, "*.md"]
      |> Path.join()
      |> Path.wildcard()
      |> Enum.sort()
    else
      warn "Cannot access `posts/'. No post will be generated."
      []
    end
  end

  @spec launch(Build.mode, [binary], map()) :: [Error.result(Post.t)]
  defp launch(mode, files, proj)

  defp launch(:parallel, files, proj) do
    files
    |> Task.async_stream(Post, :load, [proj], @async_opt)
    |> Enum.map(&(elem &1, 1))
  end

  defp launch(:sequential, files, proj) do
    files |> Enum.map(&Post.load(&1, proj))
  end
end
