defmodule Serum.Build.FragmentGenerator do
  alias Serum.Fragment
  alias Serum.Page
  alias Serum.Post
  alias Serum.PostList
  alias Serum.ProjectInfo, as: Proj
  alias Serum.Result

  @spec to_fragment(map(), map()) :: Result.t([Fragment.t()])
  def to_fragment(map, proj) do
    IO.puts("Generating fragments...")

    tasks = [
      Task.async(fn -> task_fun(map.pages, Page, proj) end),
      Task.async(fn -> task_fun(map.posts, Post, proj) end),
      Task.async(fn -> list_task_fun(map.posts, map.tag_map, proj) end)
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

  @spec list_task_fun([Post.t()], map(), Proj.t()) :: Result.t([Fragment.t()])
  defp list_task_fun(posts, tag_map, proj) do
    IO.puts("Generating post lists...")

    all_posts = PostList.generate(nil, posts, proj)

    tag_lists =
      tag_map
      |> Task.async_stream(fn {tag, posts} ->
        PostList.generate(tag, posts, proj)
      end)
      |> Enum.map(&elem(&1, 1))

    [all_posts | tag_lists]
    |> Task.async_stream(PostList, :to_fragments, [])
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate_values(:fragment_generator)
    |> case do
      {:ok, fragments} ->
        {:ok, List.flatten(fragments)}

      {:error, _} = error ->
        error
    end
  end
end
