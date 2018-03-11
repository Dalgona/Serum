defmodule Serum.Build.Pass1 do
  @moduledoc """
  This module takes care of the first pass of site building process.

  In pass 1, the following modules are run sequentially or parallelly. See the
  docs for each module for more information.

  * `Serum.Build.Pass1.PageBuilder`
  * `Serum.Build.Pass1.PostBuilder`

  After executing these two modules, the following tasks are performed:

  1. Generates a tag map, where its keys are all tags existing in the project
    and values are lists of `Serum.PostInfo` objects which has the key as one of
    its tags.
  2. Generates a site context, which is a list of variable bindings used when
    rendering templates.
  """

  alias Serum.Build
  alias Serum.Build.Pass1.PageBuilder
  alias Serum.Build.Pass1.PostBuilder
  alias Serum.GlobalBindings
  alias Serum.Result
  alias Serum.Page
  alias Serum.Post
  alias Serum.Tag

  @type result() :: %{
          pages: [Page.t()],
          posts: [Post.t()],
          tag_map: %{required(Tag.t()) => [Post.t()]},
          tag_counts: %{required(Tag.t()) => non_neg_integer()}
        }

  @doc "Starts the first pass of the building process in given build mode."
  @spec run(map(), Build.mode()) :: Result.t(result())
  def run(proj, build_mode)

  def run(proj, :parallel) do
    IO.puts("\u26a1  \x1b[1mStarting parallel build...\x1b[0m")
    t1 = Task.async(fn -> PageBuilder.run(:parallel, proj) end)
    t2 = Task.async(fn -> PostBuilder.run(:parallel, proj) end)

    with {:ok, pages} <- Task.await(t1),
         {:ok, posts} <- Task.await(t2) do
      {:ok, make_result(pages, posts)}
    else
      {:error, _} = error -> error
    end
  end

  def run(proj, :sequential) do
    IO.puts("\u231b  \x1b[1mStarting sequential build...\x1b[0m")

    with {:ok, pages} <- PageBuilder.run(:sequential, proj),
         {:ok, posts} <- PostBuilder.run(:sequential, proj) do
      {:ok, make_result(pages, posts)}
    else
      {:error, _} = error -> error
    end
  end

  @spec make_result([Page.t()], [Post.t()]) :: result()
  defp make_result(pages, posts) do
    pages = Enum.sort(pages, &(&1.order < &2.order))
    posts = Enum.sort(posts, &(&1.raw_date > &2.raw_date))
    tag_map = get_tag_map(posts)
    tag_counts = Enum.map(tag_map, fn {k, v} -> {k, Enum.count(v)} end)

    GlobalBindings.put(:all_pages, pages)
    GlobalBindings.put(:all_posts, posts)
    GlobalBindings.put(:all_tags, tag_counts)

    %{pages: pages, posts: posts, tag_map: tag_map, tag_counts: tag_counts}
  end

  @spec get_tag_map([Post.t()]) :: map()
  defp get_tag_map(all_posts) do
    all_tags =
      Enum.reduce(all_posts, MapSet.new(), fn info, acc ->
        MapSet.union(acc, MapSet.new(info.tags))
      end)

    for tag <- all_tags, into: %{} do
      posts = Enum.filter(all_posts, &(tag in &1.tags))
      {tag, posts}
    end
  end
end
