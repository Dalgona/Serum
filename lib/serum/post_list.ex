defmodule Serum.PostList do
  alias Serum.Result
  alias Serum.Fragment
  alias Serum.Post
  alias Serum.Renderer
  alias Serum.Tag
  alias Serum.Template

  @type t :: %__MODULE__{
          tag: maybe_tag(),
          page: pos_integer(),
          max_page: pos_integer(),
          title: binary(),
          posts: [Post.t()],
          list_url: binary(),
          output: binary()
        }
  @type maybe_tag :: Tag.t() | nil

  defstruct [:tag, :page, :max_page, :title, :posts, :list_url, :output]

  @spec generate(maybe_tag(), [Post.t()], map()) :: [t()]
  def generate(tag, posts, proj) do
    paginate? = proj.pagination
    num_posts = proj.posts_per_page

    paginated_posts =
      posts
      |> make_chunks(paginate?, num_posts)
      |> Enum.with_index(1)

    max_page = length(paginated_posts)
    list_dir = (tag && Path.join("tags", tag.name)) || "posts"

    Enum.map(paginated_posts, fn {posts, page} ->
      %__MODULE__{
        tag: tag,
        page: page,
        max_page: max_page,
        title: list_title(tag, proj),
        posts: posts,
        list_url: Path.join([proj.base_url, list_dir, "page-#{page}.html"]),
        output: Path.join([proj.dest, list_dir, "page-#{page}.html"])
      }
    end)
  end

  @spec make_chunks([Post.t()], boolean(), pos_integer()) :: [[Post.t()]]
  defp make_chunks(posts, paginate?, num_posts)
  defp make_chunks(posts, false, _), do: [posts]

  defp make_chunks(posts, true, num_posts) do
    Enum.chunk_every(posts, num_posts)
  end

  @spec to_fragment([t()]) :: Result.t([Fragment.t()])
  def to_fragment(post_lists) do
    case to_html(post_lists) do
      {:ok, htmls} ->
        [first | rest] =
          post_lists
          |> Stream.zip(htmls)
          |> Enum.map(fn {list, html} -> Fragment.new(:list, list, html) end)

        first_dup = %Fragment{
          first
          | output: first.output |> Path.dirname() |> Path.join("index.html")
        }

        {:ok, [first_dup, first | rest]}

      {:error, _} = error ->
        error
    end
  end

  @spec to_html([t()]) :: Result.t(binary())
  def to_html(post_lists) do
    template = Template.get("list")
    render([nil | post_lists], [], template)
  end

  @spec render([t()], [Result.t(binary())], Template.t()) :: Result.t([binary()])

  defp render([_last], acc, _template) do
    acc
    |> Enum.reverse()
    |> Result.aggregate_values(:render)
  end

  defp render([prev, curr | rest], acc, template) do
    next = List.first(rest)

    bindings = [
      header: curr.title,
      posts: curr.posts,
      current_page: curr.page,
      max_page: curr.max_page,
      prev_page: prev && prev.list_url,
      next_page: next && next.list_url
    ]

    rendered = Renderer.render_fragment(template, bindings)

    render([curr | rest], [rendered | acc], template)
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
