defmodule Serum.Build.Pass2.IndexBuilder do
  @moduledoc """
  During pass 2, IndexBuilder does the following:

  1. Renders a list of all blog posts and saves as an HTML document to the
    output directory.
  2. Loops through the tag map generated in the first pass, rendering a list of
    blog posts filtered by each tag.
  """

  import Serum.Util
  alias Serum.Error
  alias Serum.Build
  alias Serum.Post
  alias Serum.PostList
  alias Serum.Renderer
  alias Serum.Tag

  @doc "Starts the IndexBuilder."
  @spec run(Build.mode, [Post.t()], map(), map()) :: Error.result
  def run(mode, posts, tag_map, proj) do
    with {:ok, frags1} <- index_task({nil, posts}, proj),
         result = launch(mode, tag_map, proj),
         {:ok, frags2} <- Error.filter_results_with_values(result, :index_builder)
    do
      {:ok, frags1 ++ frags2}
    else
      {:error, _} = error -> error
    end
  end

  @spec launch(Build.mode, map(), map()) :: [Error.result(Fragment.t())]
  defp launch(mode, tag_map, proj)

  defp launch(:parallel, tag_map, proj) do
    tag_map
    |> Task.async_stream(__MODULE__, :index_task, [proj])
    |> Enum.map(&elem(&1, 1))
  end

  defp launch(:sequential, tag_map, proj) do
    tag_map
    |> Enum.map(&index_task(&1, proj))
  end

  @spec index_task({nil | Tag.t, [Post.t]}, map()) :: Error.result(Fragment.t())
  def index_task({tag, posts}, proj) do
    tag
    |> PostList.generate(posts, proj)
    |> PostList.to_fragment(proj)
  end
end
