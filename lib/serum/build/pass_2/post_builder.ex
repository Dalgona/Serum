defmodule Serum.Build.Pass2.PostBuilder do
  @moduledoc """
  During pass 2, PostBuilder does the following:

  1. Loops through the list of all blog posts. Renders the full HTML page of a
    blog post for each `Serum.Post` object in the list.
  """

  import Serum.Util
  alias Serum.Error
  alias Serum.Build
  alias Serum.Renderer
  alias Serum.Post

  @async_opt [max_concurrency: System.schedulers_online * 10]

  @doc "Starts the second pass of PostBuilder."
  @spec run(Build.mode(), [Post.t()], map()) :: Error.result()
  def run(mode, posts, proj) do
    postdir = Path.join proj.dest, "posts"
    File.mkdir_p! postdir
    msg_mkdir postdir
    result = launch mode, posts, proj
    Error.filter_results result, :post_builder
  end

  @spec launch(Build.mode, [Post.t], map()) :: [Error.result]
  defp launch(mode, files, proj)

  defp launch(:parallel, files, proj) do
    files
    |> Task.async_stream(__MODULE__, :post_task, [proj], @async_opt)
    |> Enum.map(&(elem &1, 1))
  end

  defp launch(:sequential, files, proj) do
    files |> Enum.map(&post_task(&1, proj))
  end

  @doc false
  @spec post_task(Post.t, map()) :: Error.result

  def post_task(post, proj) do
    srcpath = post.file
    destpath = post.output
    case Post.to_html(post, proj) do
      {:ok, html} ->
        fwrite destpath, html
        msg_gen srcpath, destpath
        :ok
      {:error, _} = error -> error
    end
  end
end
