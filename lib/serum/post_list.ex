defmodule Serum.PostList do
  @moduledoc """
  Defines a struct representing a list of blog posts.

  ## Fields

  * `tag`: Specifies by which tag the posts are filtered. Can be `nil`
  * `current_page`: Number of current page
  * `max_page`: Number of the last page
  * `title`: Title of the list
  * `posts`: A list of `Post` structs
  * `url`: Absolute URL of this list page in the website
  * `prev_url`: Absolute URL of the previous list page. Can be `nil` if this is
    the first page
  * `next_url`: Absolute URL of the next list page. Can be `nil` if this is
    the last page
  * `output`: Destination path
  """

  alias Serum.Result
  alias Serum.Fragment
  alias Serum.Post
  alias Serum.Renderer
  alias Serum.Tag
  alias Serum.Template

  @type t :: %__MODULE__{
          tag: maybe_tag(),
          current_page: pos_integer(),
          max_page: pos_integer(),
          title: binary(),
          posts: [Post.t()],
          url: binary(),
          prev_url: binary() | nil,
          next_url: binary() | nil,
          output: binary()
        }
  @type maybe_tag :: Tag.t() | nil

  defstruct [
    :tag,
    :current_page,
    :max_page,
    :title,
    :posts,
    :url,
    :prev_url,
    :next_url,
    :output
  ]

  @spec generate(maybe_tag(), [Post.t()], map()) :: [t()]
  def generate(tag, posts, proj)

  def generate(tag, [], proj) do
    list_dir = (tag && Path.join("tags", tag.name)) || "posts"

    [
      %__MODULE__{
        tag: tag,
        current_page: 1,
        max_page: 1,
        title: list_title(tag, proj),
        posts: [],
        url: Path.join([proj.base_url, list_dir, "page-1.html"]),
        output: Path.join([proj.dest, list_dir, "page-1.html"]),
        prev_url: nil,
        next_url: nil
      }
    ]
  end

  def generate(tag, posts, proj) do
    paginate? = proj.pagination
    num_posts = proj.posts_per_page

    paginated_posts =
      posts
      |> make_chunks(paginate?, num_posts)
      |> Enum.with_index(1)

    max_page = length(paginated_posts)
    list_dir = (tag && Path.join("tags", tag.name)) || "posts"

    lists =
      Enum.map(paginated_posts, fn {posts, page} ->
        %__MODULE__{
          tag: tag,
          current_page: page,
          max_page: max_page,
          title: list_title(tag, proj),
          posts: posts,
          url: Path.join([proj.base_url, list_dir, "page-#{page}.html"]),
          output: Path.join([proj.dest, list_dir, "page-#{page}.html"])
        }
      end)

    put_adjacent_urls([nil | lists], [])
  end

  @spec put_adjacent_urls([t()], [t()]) :: [t()]
  defp put_adjacent_urls(lists, acc)
  defp put_adjacent_urls([_last], acc), do: Enum.reverse(acc)

  defp put_adjacent_urls([prev, curr | rest], acc) do
    next = List.first(rest)

    updated_curr = %__MODULE__{
      curr
      | prev_url: prev && prev.url,
        next_url: next && next.url
    }

    put_adjacent_urls([curr | rest], [updated_curr | acc])
  end

  @spec make_chunks([Post.t()], boolean(), pos_integer()) :: [[Post.t()]]
  defp make_chunks(posts, paginate?, num_posts)
  defp make_chunks(posts, false, _), do: [posts]

  defp make_chunks(posts, true, num_posts) do
    Enum.chunk_every(posts, num_posts)
  end

  @spec to_fragments([t()]) :: Result.t([Fragment.t()])
  def to_fragments(post_lists) do
    post_lists
    |> Task.async_stream(&to_fragment/1)
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate_values(:to_fragments)
    |> case do
      {:ok, [first | rest]} ->
        first_dup = %Fragment{
          first
          | output: first.output |> Path.dirname() |> Path.join("index.html")
        }

        {:ok, [first_dup, first | rest]}

      {:error, _} = error ->
        error
    end
  end

  @spec to_fragment(t()) :: Result.t(Fragment.t())
  defp to_fragment(post_list) do
    metadata =
      post_list
      |> Map.drop([:__struct__, :output])
      |> Map.put(:type, :list)

    bindings = [page: metadata]
    template = Template.get("list")

    case Renderer.render_fragment(template, bindings) do
      {:ok, html} ->
        {:ok, Fragment.new(nil, post_list.output, metadata, html)}

      {:error, _} = error ->
        error
    end
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
