defmodule Serum.Build.Pass2.PostBuilder do
  @moduledoc """
  During pass 2, PostBuilder does the following:

  1. Loops through the list of all blog posts. Renders the full HTML page of a
    blog post for each `Serum.Post` object in the list.
  """

  import Serum.Util
  alias Serum.Error
  alias Serum.Fragment
  alias Serum.Build
  alias Serum.Renderer
  alias Serum.Post

  @doc "Starts the second pass of PostBuilder."
  @spec run(Build.mode(), [Post.t()], map()) :: Error.result()
  def run(mode, posts, proj) do
    result = launch mode, posts, proj
    Error.filter_results result, :post_builder
  end

  @spec launch(Build.mode, [Post.t], map()) :: [Error.result(Fragment.t())]
  defp launch(mode, files, proj)

  defp launch(:parallel, files, proj) do
    files
    |> Task.async_stream(Post, :to_fragment, [proj])
    |> Enum.map(&(elem &1, 1))
  end

  defp launch(:sequential, files, proj) do
    files |> Enum.map(&Post.to_fragment(&1, proj))
  end
end
