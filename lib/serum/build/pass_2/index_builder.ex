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
  alias Serum.PostList
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

  defp launch(:parallel, tag_map, state) do
    tag_map
    |> Task.async_stream(__MODULE__, :index_task, [state], @async_opt)
    |> Enum.map(&elem(&1, 1))
  end

  defp launch(:sequential, tag_map, state) do
    tag_map
    |> Enum.map(&index_task(&1, state))
  end

  @doc false
  @spec index_task({nil | Tag.t, [PostInfo.t]}, state) :: Error.result

  def index_task({tag, posts}, state) do
    proj = state.project_info
    lists = PostList.generate(tag, posts, proj)

    case PostList.to_html(lists, proj) do
      {:ok, htmls} -> :ok
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
end
