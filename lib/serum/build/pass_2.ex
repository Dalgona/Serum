defmodule Serum.Build.Pass2 do
  @moduledoc """
  This module takes care of the second pass of site building process.

  In pass 2, the following modules are run sequentially or parallelly. See the
  docs for each module for more information.

  * `Serum.Build.Pass2.PageBuilder`
  * `Serum.Build.Pass2.PostBuilder`
  * `Serum.Build.Pass2.IndexBuilder`
  """

  alias Serum.Build
  alias Serum.Build.Pass2.PageBuilder
  alias Serum.Build.Pass2.PostBuilder
  alias Serum.Build.Pass2.IndexBuilder
  alias Serum.Fragment
  alias Serum.GlobalBindings
  alias Serum.Page
  alias Serum.Post
  alias Serum.Result

  @doc "Starts the second pass of the building process in given build mode."
  @spec run(map(), map(), Build.mode()) :: Result.t([Fragment.t()])
  def run(map, proj, build_mode) do
    proj
    |> Map.from_struct()
    |> Map.merge(map)
    |> GlobalBindings.load()

    result = do_run(map.pages, map.posts, map.tag_map, proj, build_mode)

    result
    |> Result.aggregate_values(:build_pass2)
    |> case do
      {:ok, results} -> {:ok, List.flatten(results)}
      {:error, _} = error -> error
    end
  end

  @spec do_run([Page.t()], [Post.t()], map(), map(), Build.mode()) ::
    Result.t([[Fragment.t()]])

  defp do_run(pages, posts, tag_map, proj, build_mode)

  defp do_run(pages, posts, tag_map, proj, :parallel) do
    t1 = Task.async(PageBuilder, :run, [:parallel, pages, proj])
    t2 = Task.async(PostBuilder, :run, [:parallel, posts, proj])
    t3 = Task.async(IndexBuilder, :run, [:parallel, posts, tag_map, proj])
    Enum.map([t1, t2, t3], &Task.await/1)
  end

  defp do_run(pages, posts, tag_map, proj, :sequential) do
    r1 = PageBuilder.run(:sequential, pages, proj)
    r2 = PostBuilder.run(:sequential, posts, proj)
    r3 = IndexBuilder.run(:sequential, posts, tag_map, proj)
    [r1, r2, r3]
  end
end
