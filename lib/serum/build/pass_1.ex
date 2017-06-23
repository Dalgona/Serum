defmodule Serum.Build.Pass1 do
  alias Serum.Build
  alias Serum.Build.Pass1.PageBuilder
  alias Serum.Build.Pass1.PostBuilder
  alias Serum.Error
  alias Serum.PageInfo
  alias Serum.PostInfo

  @spec run(Build.mode, Build.state) :: Error.result(Build.state)

  def run(:parallel, state) do
    IO.puts "\u26a1  \x1b[1mStarting parallel build...\x1b[0m"
    t1 = Task.async fn -> PageBuilder.run :parallel, state end
    t2 = Task.async fn -> PostBuilder.run :parallel, state end
    with {:ok, pages} <- Task.await(t1),
         {:ok, posts} <- Task.await(t2)
    do
      {:ok, update_state(pages, posts, state)}
    else
      {:error, _, _} = error -> error
    end
  end

  def run(:sequential, state) do
    IO.puts "\u231b  \x1b[1mStarting sequential build...\x1b[0m"
    with {:ok, pages} <- PageBuilder.run(:parallel, state),
         {:ok, posts} <- PostBuilder.run(:parallel, state)
    do
      {:ok, update_state(pages, posts, state)}
    else
      {:error, _, _} = error -> error
    end
  end

  @spec update_state([PageInfo.t], [PostInfo.t], Build.state) :: Build.state

  defp update_state(pages, posts, state) do
    pages = Enum.sort pages, & &1.order < &2.order
    posts = Enum.sort posts, & &1.raw_date > &2.raw_date
    tag_map = get_tag_map posts
    tags = Enum.map tag_map, fn {k, v} -> {k, Enum.count(v)} end
    proj = state.project_info
    site_ctx = [
      site_name: proj.site_name, site_description: proj.site_description,
      author: proj.author, author_email: proj.author_email,
      pages: pages, posts: posts, tags: tags
    ]
    state
    |> Map.put(:site_ctx, site_ctx)
    |> Map.put(:tag_map, tag_map)
  end

  @spec get_tag_map([PostInfo.t]) :: map

  defp get_tag_map(all_posts) do
    all_tags =
      Enum.reduce all_posts, MapSet.new(), fn info, acc ->
        MapSet.union acc, MapSet.new(info.tags)
      end
    for tag <- all_tags, into: %{} do
      posts = Enum.filter all_posts, &(tag in &1.tags)
      {tag, posts}
    end
  end
end
