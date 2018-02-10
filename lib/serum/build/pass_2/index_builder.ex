defmodule Serum.Build.Pass2.IndexBuilder do
  @moduledoc """
  During pass 2, IndexBuilder does the following:

  1. Renders a list of all blog posts and saves as an HTML document to the
    output directory.
  2. Loops through the tag map generated in the first pass, rendering a list of
    blog posts filtered by each tag.
  """

  alias Serum.Result
  alias Serum.Build
  alias Serum.Post
  alias Serum.PostList
  alias Serum.Tag

  @doc "Starts the IndexBuilder."
  @spec run(Build.mode(), [Post.t()], map(), map()) :: Result.t([Fragment.t()])
  def run(mode, posts, tag_map, proj) do
    with {:ok, frags1} <- index_task({nil, posts}, proj),
         result = launch(mode, tag_map, proj),
         {:ok, frags2} <- Result.aggregate_values(result, :index_builder) do
      {:ok, List.flatten([frags1 | frags2])}
    else
      {:error, _} = error -> error
    end
  end

  @spec launch(Build.mode(), map(), map()) :: [Result.t(Fragment.t())]
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

  @spec index_task({nil | Tag.t(), [Post.t()]}, map()) :: Result.t(Fragment.t())
  def index_task({tag, posts}, proj) do
    tag
    |> PostList.generate(posts, proj)
    |> PostList.to_fragment()
  end
end
