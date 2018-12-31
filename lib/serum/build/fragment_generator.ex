defmodule Serum.Build.FragmentGenerator do
  alias Serum.Build.Pass2.IndexBuilder
  alias Serum.Fragment
  alias Serum.Page
  alias Serum.Post
  alias Serum.ProjectInfo, as: Proj
  alias Serum.Result

  @spec to_fragment(map(), map()) :: Result.t([Fragment.t()])
  def to_fragment(map, proj) do
    IO.puts("Generating fragments...")

    tasks = [
      Task.async(fn -> task_fun(map.pages, Page, proj) end),
      Task.async(fn -> task_fun(map.posts, Post, proj) end),
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

  @spec task_fun([struct()], module(), Proj.t()) :: Result.t([Fragment.t()])
  defp task_fun(items, struct, proj) do
    items
    |> Task.async_stream(struct, :to_fragment, [proj])
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate_values(:fragment_generator)
  end
end
