defmodule Serum.Build.Pass2 do
  alias Serum.Build.Pass2.PageBuilder
  alias Serum.Build.Pass2.PostBuilder
  alias Serum.Build.Pass2.IndexBuilder
  alias Serum.Fragment
  alias Serum.Page
  alias Serum.Post
  alias Serum.Result

  @spec run(Result.t(map()), map()) :: Result.t([Fragment.t()])
  def run({:error, _} = error), do: error

  def run({:ok, map}, proj) do
    result = do_run(map.pages, map.posts, map.tag_map, proj)

    result
    |> Result.aggregate_values(:build_pass2)
    |> case do
      {:ok, results} -> {:ok, List.flatten(results)}
      {:error, _} = error -> error
    end
  end

  @spec do_run([Page.t()], [Post.t()], map(), map()) :: Result.t([[Fragment.t()]])
  defp do_run(pages, posts, tag_map, proj) do
    t1 = Task.async(PageBuilder, :run, [pages, proj])
    t2 = Task.async(PostBuilder, :run, [posts, proj])
    t3 = Task.async(IndexBuilder, :run, [posts, tag_map, proj])
    Enum.map([t1, t2, t3], &Task.await/1)
  end
end
