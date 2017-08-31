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
  alias Serum.PostInfo
  alias Serum.Renderer

  @type state :: Build.state

  @async_opt [max_concurrency: System.schedulers_online * 10]

  @doc "Starts the IndexBuilder."
  @spec run(Build.mode, state) :: Error.result

  def run(mode, state) do
    IO.puts "Generating posts index..."

    postdir = Path.join state.dest, "posts"
    File.mkdir_p! postdir
    msg_mkdir postdir
    all_posts = state.site_ctx[:posts]
    title = state.project_info.list_title_all
    save_list Path.join(postdir, "index.html"), title, all_posts, state

    #test {nil, state.site_ctx[:posts]}, state

    tags = state.tag_map
    result = launch_tag mode, tags, state
    Error.filter_results result, :index_builder
  end

  defp test({tag, posts}, state) do
    pagination? = state.project_info.pagination
    posts_per_page = state.project_info.posts_per_page

    list_path = tag && "tags/" <> tag.name || "posts"
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

    case render_lists posts, 1, [], new_state do
      {:ok, htmls} -> save_lists htmls, list_dir
      {:error, _} = error -> error
    end
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

  @spec launch_tag(Build.mode, map, state) :: [Task.t]

  defp launch_tag(:parallel, tagmap, state) do
    %{dest: dir} = state
    tagmap
    |> Task.async_stream(__MODULE__, :tag_task, [dir, state], @async_opt)
    |> Enum.map(&elem(&1, 1))
  end

  defp launch_tag(:sequential, tagmap, state) do
    %{dest: dir} = state
    tagmap
    |> Enum.map(&tag_task(&1, dir, state))
  end

  @doc false
  @spec tag_task({Serum.Tag.t, [PostInfo.t]}, binary, state) :: :ok

  def tag_task({tag, posts}, dest, state) do
    tagdir = Path.join [dest, "tags", tag.name]
    fmt = state.project_info.list_title_tag
    title = fmt |> :io_lib.format([tag.name]) |> IO.iodata_to_binary
    File.mkdir_p! tagdir
    msg_mkdir tagdir
    save_list Path.join(tagdir, "index.html"), title, posts, state
  end

  @spec save_list(binary, binary, [PostInfo.t], state) :: :ok

  defp save_list(path, title, posts, state) do
    list_ctx = [header: title, posts: posts]
    case Renderer.render "list", list_ctx, [page_title: title], state do
      {:ok, html} ->
        fwrite path, html
        msg_gen path
      error -> error
    end
  end

  """
  # for the first page
  path_index = Path.join state.list_dir, "index.html"
  fwrite path_index, html
  msg_gen path_index

  path = Path.join state.list_dir, "page-1.html"
  fwrite path, html
  msg_gen path

  # for other pages
  path = Path.join state.list_dir, "page-# {page_num}.html"
  fwrite path, html
  msg_gen path
  """

  @spec render_lists([[PostInfo.t]], integer, [Error.result(binary)], state)
    :: Error.result([binary])

  defp render_lists(paginated_posts, page_num, acc, state)

  defp render_lists([page], 1, _acc, state) do
    # The only page
    rendered = render_list page, 1, true, true, state
    [rendered]
    |> Error.filter_results_with_values(:render_lists)
  end

  defp render_lists([page], page_num, acc, state) do
    # The last page
    rendered = render_list page, page_num, false, true, state
    [rendered|acc]
    |> Enum.reverse()
    |> Error.filter_results_with_values(:render_lists)
  end

  defp render_lists([page|rest], 1, acc, state) do
    # The first page
    rendered = render_list page, 1, true, false, state
    render_lists rest, 2, [rendered|acc], state
  end

  defp render_lists([page|rest], page_num, acc, state) do
    # Other pages
    rendered = render_list page, page_num, false, false, state
    render_lists rest, page_num + 1, [rendered|acc], state
  end

  @spec render_list([PostInfo.t], integer, boolean, boolean, state)
    :: Error.result(binary)

  defp render_list(posts, page_num, first?, last?, state) do
    base = state.project_info.base_url
    path = state.list_path
    prev = if first?, do: Path.join([base, path, "page-#{page_num - 1}.html"])
    next = if last?, do: Path.join([base, path, "page-#{page_num + 1}.html"])
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
end
