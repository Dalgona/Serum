defmodule Serum.PostList do
  @moduledoc false

  _moduledocp = """
  Defines functions internally used by Serum to create
  `Serum.V2.PostList` structs.
  """

  alias Serum.V2.BuildContext
  alias Serum.V2.Post
  alias Serum.V2.PostList
  alias Serum.V2.Project
  alias Serum.V2.Project.BlogConfiguration
  alias Serum.V2.Tag

  @type maybe_tag :: Tag.t() | nil

  @spec generate(maybe_tag(), [Post.t()], BuildContext.t()) :: [PostList.t()]
  def generate(tag, posts, %BuildContext{project: %Project{} = proj} = context) do
    %BlogConfiguration{} = blog = proj.blog
    base_url = proj.base_url.path
    paginate? = blog.pagination
    num_posts = blog.posts_per_page
    list_dir = (tag && Path.join("tags", tag.name)) || "posts"

    paginated_posts =
      posts
      |> make_chunks(paginate?, num_posts)
      |> Enum.with_index(1)

    [list | lists] =
      Enum.map(paginated_posts, fn {posts, page} ->
        %PostList{
          tag: tag,
          current_page: page,
          last_page: length(paginated_posts),
          title: list_title(tag, blog),
          posts: posts,
          url: Path.join([base_url, list_dir, "page-#{page}.html"]),
          dest: Path.join([context.dest_dir, list_dir, "page-#{page}.html"]),
          extras: %{}
        }
      end)

    first_dup = %PostList{
      list
      | url: Path.join([base_url, list_dir, "index.html"]),
        dest: Path.join([context.dest_dir, list_dir, "index.html"])
    }

    [first_dup, list | lists]
  end

  @spec make_chunks([Post.t()], boolean(), pos_integer()) :: [[map()]]
  defp make_chunks(posts, paginate?, num_posts)
  defp make_chunks([], _, _), do: [[]]
  defp make_chunks(posts, false, _), do: [posts]

  defp make_chunks(posts, true, num_posts) do
    Enum.chunk_every(posts, num_posts)
  end

  @spec list_title(maybe_tag(), BlogConfiguration.t()) :: binary()
  defp list_title(tag, blog)
  defp list_title(nil, %BlogConfiguration{} = blog), do: blog.list_title_all

  defp list_title(%Tag{name: tag_name}, %BlogConfiguration{} = blog) do
    blog.list_title_tag
    |> :io_lib.format([tag_name])
    |> IO.iodata_to_binary()
  end
end
