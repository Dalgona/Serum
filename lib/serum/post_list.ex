defmodule Serum.PostList do
  @moduledoc false

  _moduledocp = """
  Defines functions internally used by Serum to create
  `Serum.V2.PostList` structs.
  """

  require Serum.V2.Result, as: Result
  alias Serum.Plugin.Client, as: PluginClient
  alias Serum.V2.PostList
  alias Serum.V2.Tag

  @type maybe_tag :: Tag.t() | nil

  @spec generate(maybe_tag(), [map()], map()) :: Result.t([PostList.t()])
  def generate(tag, posts, proj) do
    paginate? = proj.pagination
    num_posts = proj.posts_per_page

    paginated_posts =
      posts
      |> make_chunks(paginate?, num_posts)
      |> Enum.with_index(1)

    last_page = length(paginated_posts)
    list_dir = (tag && Path.join("tags", tag.name)) || "posts"
    list_title = list_title(tag, proj)

    [list | lists] =
      Enum.map(paginated_posts, fn {posts, page} ->
        %PostList{
          tag: tag,
          current_page: page,
          last_page: last_page,
          title: list_title,
          posts: posts,
          url: Path.join([proj.base_url, list_dir, "page-#{page}.html"]),
          dest: Path.join([proj.dest, list_dir, "page-#{page}.html"]),
          extras: %{}
        }
      end)

    first_dup = %PostList{
      list
      | url: Path.join([proj.base_url, list_dir, "index.html"]),
        dest: Path.join([proj.dest, list_dir, "index.html"])
    }

    [first_dup, list | lists]
    |> Enum.map(&PluginClient.processed_list/1)
    |> Result.aggregate("failed to generate post list \"#{list_title}\":")
  end

  @spec compact(PostList.t()) :: map()
  def compact(%PostList{} = list) do
    list
    |> Map.drop(~w(__struct__ dest)a)
    |> Map.put(:type, :list)
  end

  @spec make_chunks([map()], boolean(), pos_integer()) :: [[map()]]
  defp make_chunks(posts, paginate?, num_posts)
  defp make_chunks([], _, _), do: [[]]
  defp make_chunks(posts, false, _), do: [posts]

  defp make_chunks(posts, true, num_posts) do
    Enum.chunk_every(posts, num_posts)
  end

  @spec list_title(maybe_tag(), map()) :: binary()
  defp list_title(tag, proj)
  defp list_title(nil, proj), do: proj.list_title_all

  defp list_title(%Tag{name: tag_name}, proj) do
    proj.list_title_tag
    |> :io_lib.format([tag_name])
    |> IO.iodata_to_binary()
  end
end
