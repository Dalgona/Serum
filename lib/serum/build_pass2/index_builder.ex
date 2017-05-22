defmodule Serum.BuildPass2.IndexBuilder do
  @moduledoc """
  This module contains functions for generating index pages of blog posts.
  """

  import Serum.Util
  alias Serum.Error
  alias Serum.Build
  alias Serum.Renderer

  @type state :: Build.state

  @async_opt [max_concurrency: System.schedulers_online * 10]

  @spec run(Build.mode, state) :: Error.result

  def run(mode, state) do
    postdir = "#{state.dest}posts/"
    if File.exists? postdir do
      all_posts = state.posts
      title = state.project_info.list_title_all

      IO.puts "Generating posts index..."
      save_list "#{postdir}index.html", title, Enum.reverse(all_posts), state

      tags = get_tag_map all_posts
      result = launch_tag mode, tags, state
      Error.filter_results result, :index_builder
    else
      {:error, :file_error, {:enoent, postdir, 0}}
    end
  end

  @spec get_tag_map([Serum.PostInfo.t]) :: map

  def get_tag_map(all_posts) do
    all_tags =
      Enum.reduce all_posts, MapSet.new(), fn info, acc ->
        MapSet.union acc, MapSet.new(info.tags)
      end
    for tag <- all_tags, into: %{} do
      posts =
        all_posts
        |> Enum.filter(&(tag in &1.tags))
        |> Enum.sort(&(&1.file > &2.file))
      {tag, posts}
    end
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
