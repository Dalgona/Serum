defmodule Serum.Build.Pass2.IndexBuilder do
  alias Serum.Result
  alias Serum.Post
  alias Serum.PostList
  alias Serum.Tag

  @spec run([Post.t()], map(), map()) :: Result.t([Fragment.t()])
  def run(posts, tag_map, proj) do
    with {:ok, frags1} <- index_task({nil, posts}, proj),
         result = launch(tag_map, proj),
         {:ok, frags2} <- Result.aggregate_values(result, :index_builder) do
      {:ok, List.flatten([frags1 | frags2])}
    else
      {:error, _} = error -> error
    end
  end

  @spec launch(map(), map()) :: [Result.t(Fragment.t())]
  defp launch(tag_map, proj) do
    tag_map
    |> Task.async_stream(__MODULE__, :index_task, [proj])
    |> Enum.map(&elem(&1, 1))
  end

  @spec index_task({nil | Tag.t(), [Post.t()]}, map()) :: Result.t(Fragment.t())
  def index_task({tag, posts}, proj) do
    tag
    |> PostList.generate(posts, proj)
    |> PostList.to_fragments()
  end
end
