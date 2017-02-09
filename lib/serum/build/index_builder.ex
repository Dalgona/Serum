defmodule Serum.Build.IndexBuilder do
  @moduledoc """
  This module contains functions for generating index pages of blog posts.
  """

  import Serum.Util
  alias Serum.Error
  alias Serum.Build
  alias Serum.Build.Renderer
  alias Serum.BuildDataStorage
  alias Serum.PostInfoStorage
  alias Serum.ProjectInfoStorage

  @type state :: Build.state

  @async_opt [max_concurrency: System.schedulers_online * 10]

  @spec run(Build.build_mode, String.t, String.t, Build.state) :: Error.result

  def run(mode, _src, dest, state) do
    dstdir = "#{dest}posts/"
    if File.exists? dstdir do
      all_posts = PostInfoStorage.all owner()
      title = ProjectInfoStorage.get owner(), :list_title_all

      IO.puts "Generating posts index..."
      save_list "#{dstdir}index.html", title, Enum.reverse(all_posts)

      tags = get_tag_map all_posts
      result = launch_tag mode, tags, dest
      Error.filter_results result, :index_builder
    else
      {:error, :file_error, {:enoent, dstdir, 0}}
    end
  end

  @spec get_tag_map([Serum.PostInfo.t]) :: map

  defp get_tag_map(all_posts) do
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

  @spec launch_tag(Build.build_mode, map, String.t) :: [Task.t]

  defp launch_tag(:parallel, tagmap, dir) do
    own = owner()
    tagmap
    |> Task.async_stream(__MODULE__, :tag_task, [dir, own], @async_opt)
    |> Enum.map(&elem(&1, 1))
  end

  defp launch_tag(:sequential, tagmap, dir) do
    own = self()
    tagmap
    |> Enum.map(&tag_task(&1, dir, own))
  end

  @spec tag_task({Serum.Tag.t, [Serum.PostInfo.t]}, String.t, pid) :: :ok

  def tag_task({tag, posts}, dest, owner) do
    Process.link owner
    tagdir = "#{dest}tags/#{tag.name}/"
    fmt = ProjectInfoStorage.get owner(), :list_title_tag
    title = fmt |> :io_lib.format([tag.name]) |> IO.iodata_to_binary
    File.mkdir_p! tagdir
    save_list "#{tagdir}index.html", title, posts
  end

  @spec save_list(String.t, String.t, [Serum.PostInfo.t]) :: :ok

  defp save_list(path, title, posts) do
    template = BuildDataStorage.get owner(), "template", "list"
    html =
      template
      |> Renderer.render([header: title, posts: posts])
      |> Renderer.genpage([page_title: title], owner())
    fwrite path, html
    IO.puts "  GEN  #{path}"
    :ok
  end
end
