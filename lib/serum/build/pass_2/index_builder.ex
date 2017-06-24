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
  alias Serum.Renderer

  @type state :: Build.state

  @async_opt [max_concurrency: System.schedulers_online * 10]

  @doc "Starts the IndexBuilder."
  @spec run(Build.mode, state) :: Error.result

  def run(mode, state) do
    postdir = "#{state.dest}posts/"
    File.mkdir_p! postdir
    all_posts = state.site_ctx[:posts]
    title = state.project_info.list_title_all

    IO.puts "Generating posts index..."
    save_list "#{postdir}index.html", title, all_posts, state

    tags = state.tag_map
    result = launch_tag mode, tags, state
    Error.filter_results result, :index_builder
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
  @spec tag_task({Serum.Tag.t, [Serum.PostInfo.t]}, binary, state) :: :ok

  def tag_task({tag, posts}, dest, state) do
    tagdir = "#{dest}tags/#{tag.name}/"
    fmt = state.project_info.list_title_tag
    title = fmt |> :io_lib.format([tag.name]) |> IO.iodata_to_binary
    File.mkdir_p! tagdir
    save_list "#{tagdir}index.html", title, posts, state
  end

  @spec save_list(binary, binary, [Serum.PostInfo.t], state) :: :ok

  defp save_list(path, title, posts, state) do
    list_ctx = [header: title, posts: posts]
    case Renderer.render "list", list_ctx, [page_title: title], state do
      {:ok, html} ->
        fwrite path, html
        IO.puts "  GEN  #{path}"
      error -> error
    end
  end
end
