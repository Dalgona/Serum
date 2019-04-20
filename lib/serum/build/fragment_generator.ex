defmodule Serum.Build.FragmentGenerator do
  @moduledoc """
  Renders page/post/post list structs into a page fragment.
  """

  alias Serum.Fragment
  alias Serum.Page
  alias Serum.Post
  alias Serum.PostList
  alias Serum.Project
  alias Serum.Result

  @spec to_fragment(map(), map()) :: Result.t([Fragment.t()])
  def to_fragment(map, proj) do
    IO.puts("Generating fragments...")

    tasks = [
      Task.async(fn -> task_fun(map.pages, Page, proj) end),
      Task.async(fn -> task_fun(map.posts, Post, proj) end),
      Task.async(fn -> task_fun(map.lists, PostList, proj) end)
    ]

    tasks
    |> Enum.map(&Task.await/1)
    |> Result.aggregate_values(:build_pass2)
    |> case do
      {:ok, results} -> {:ok, List.flatten(results)}
      {:error, _} = error -> error
    end
  end

  @spec task_fun([struct()], module(), Project.t()) :: Result.t([Fragment.t()])
  defp task_fun(items, struct, proj) do
    items
    |> Task.async_stream(struct, :to_fragment, [proj])
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate_values(:fragment_generator)
  end
end
