defmodule Serum.Build.Pass2.IndexBuilder do
  @moduledoc """
  During pass 2, IndexBuilder does the following:

  1. Renders a list of all blog posts and saves as an HTML document to the
    output directory.
  2. Loops through the tag map generated in the first pass, rendering a list of
    blog posts filtered by each tag.
  """

  import Serum.Util
  alias Serum.Error
  alias Serum.Build
  alias Serum.Post
  alias Serum.Renderer
  alias Serum.Tag

  @type state :: Build.state

  @async_opt [max_concurrency: System.schedulers_online * 10]

  @doc "Starts the IndexBuilder."
  @spec run(Build.mode, [Post.t()], map(), state) :: Error.result

  def run(mode, posts, tag_map, state) do
    IO.puts "Generating posts index..."

    case index_task({nil, posts}, state) do
      :ok ->
        result = launch mode, tag_map, state
        Error.filter_results result, :index_builder
      {:error, _} = error -> error
    end
  end

  @spec launch(Build.mode, map, state) :: [Error.result]

  defp launch(:parallel, tagmap, state) do
    tagmap
    |> Task.async_stream(__MODULE__, :index_task, [state], @async_opt)
    |> Enum.map(&elem(&1, 1))
  end

  defp launch(:sequential, tagmap, state) do
    tagmap
    |> Enum.map(&index_task(&1, state))
  end

  @doc false
  @spec index_task({nil | Tag.t, [PostInfo.t]}, state) :: Error.result

  def index_task({tag, posts}, state) do
    pagination? = state.project_info.pagination
    posts_per_page = state.project_info.posts_per_page

    list_path = tag && Path.join("tags", tag.name) || "posts"
    list_dir = Path.join state.dest, list_path
    list_title =
      if is_nil(tag) do
        state.project_info.list_title_all
      else
        state.project_info.list_title_tag
        |> :io_lib.format([tag.name])
        |> IO.iodata_to_binary
      end
    File.mkdir_p! list_dir
    msg_mkdir list_dir

    posts = pagination? && Enum.chunk_every(posts, posts_per_page) || [posts]
    new_state =
      state
      |> Map.put(:list_path, list_path)
      |> Map.put(:list_title, list_title)
      |> Map.put(:max_page, length(posts))

    case render_lists posts, new_state do
      {:ok, htmls} -> save_lists htmls, list_dir
      {:error, _} = error -> error
    end
  end

  @spec render_lists([[PostInfo.t]], state) :: Error.result([binary])

  defp render_lists(paginated_posts, state) do
    paginated_posts
    |> Enum.with_index(1)
    |> Enum.map(fn {page, page_num} ->
      first? = page_num == 1
      last? = page_num == state.max_page
      render_list page, page_num, first?, last?, state
    end)
    |> Error.filter_results_with_values(:render_lists)
  end

  @spec render_list([PostInfo.t], integer, boolean, boolean, state)
    :: Error.result(binary)

  defp render_list(posts, page_num, first?, last?, state) do
    base = state.project_info.base_url
    path = state.list_path
    prev =
      unless first?, do: Path.join([base, path, "page-#{page_num - 1}.html"])
    next =
      unless last?, do: Path.join([base, path, "page-#{page_num + 1}.html"])
    list_ctx = [
      header: state.list_title,
      posts: posts,
      current_page: page_num,
      max_page: state.max_page,
      prev_page: prev,
      next_page: next
    ]
    Renderer.render "list", list_ctx, [page_title: state.list_title], state
  end

  @spec save_lists([binary], binary) :: :ok

  defp save_lists([first|_] = htmls, list_dir) do
    path_index = Path.join list_dir, "index.html"
    fwrite path_index, first
    msg_gen path_index
    htmls
    |> Enum.with_index(1)
    |> Enum.each(fn {html, page_num} ->
      path = Path.join list_dir, "page-#{page_num}.html"
      fwrite path, html
      msg_gen path
    end)
  end
end
