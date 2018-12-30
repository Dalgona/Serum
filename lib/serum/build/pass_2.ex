defmodule Serum.Build.Pass2 do
  alias Serum.Build.Pass2.PageBuilder
  alias Serum.Build.Pass2.PostBuilder
  alias Serum.Build.Pass2.IndexBuilder
  alias Serum.Fragment
  alias Serum.Result

  @spec run(map(), map()) :: Result.t([Fragment.t()])
  def run(map, proj) do
    tasks = [
      Task.async(PageBuilder, :run, [map.pages, proj]),
      Task.async(PostBuilder, :run, [map.posts, proj]),
      Task.async(IndexBuilder, :run, [map.posts, map.tag_map, proj])
    ]

    tasks
    |> Enum.map(&Task.await/1)
    |> Result.aggregate_values(:build_pass2)
    |> case do
      {:ok, results} -> {:ok, List.flatten(results)}
      {:error, _} = error -> error
    end
  end
end
