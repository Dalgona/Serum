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
  alias Serum.Result
  alias Serum.Page
  alias Serum.Post

  @doc "Starts the second pass of the building process in given build mode."
  @spec run(Build.mode(), [Page.t()], [Post.t()], map(), map()) ::
    Result.t(Fragment.t())

  def run(build_mode, pages, posts, tag_map, proj)

  def run(:parallel, pages, posts, tag_map, proj) do
    t1 = Task.async(PageBuilder, :run, [:parallel, pages, proj])
    t2 = Task.async(PostBuilder, :run, [:parallel, posts, proj])
    t3 = Task.async(IndexBuilder, :run, [:parallel, posts, tag_map, proj])
    [t1, t2, t3]
    |> Enum.map(&Task.await/1)
    |> Result.aggregate_values(:build_pass2)
    |> case do
      {:ok, results} -> {:ok, List.flatten(results)}
      {:error, _} = error -> error
    end
  end

  def run(:sequential, pages, posts, tag_map, proj) do
    r1 = PageBuilder.run(:sequential, pages, proj)
    r2 = PostBuilder.run(:sequential, posts, proj)
    r3 = IndexBuilder.run(:sequential, posts, tag_map, proj)
    [r1, r2, r3]
    |> Result.aggregate_values(:build_pass2)
    |> case do
      {:ok, results} -> {:ok, List.flatten(results)}
      {:error, _} = error -> error
    end
  end
end
