defmodule Serum.Build.IndexBuilder do
  @moduledoc """
  This module contains functions for generating index pages of blog posts.
  """

  import Serum.Util
  alias Serum.Error
  alias Serum.Build
  alias Serum.Build.BuildData
  alias Serum.Build.ProjectInfo
  alias Serum.Build.Renderer
  alias Serum.PostInfo
  alias Serum.Tag

  @async_opt [max_concurrency: System.schedulers_online * 10]

  @spec run(String.t, String.t, Build.build_mode) :: Error.result

  def run(_src, dest, mode) do
    dstdir = "#{dest}posts/"
    if File.exists? dstdir do
      infolist = PostInfo.all owner()
      title = ProjectInfo.get owner(), :list_title_all

      IO.puts "Generating posts index..."
      save_list "#{dstdir}index.html", title, Enum.reverse(infolist)

      tags = update_tags owner(), infolist
      result = launch_tag mode, tags, dest
      Error.filter_results result, :index_builder
    else
      {:error, :file_error, {:enoent, dstdir, 0}}
    end
  end

  @spec update_tags(pid, [Serum.PostInfo.t]) :: :ok

  defp update_tags(owner, infolist) do
    Tag.init owner
    for info <- infolist,
      do: Enum.each info.tags, &Tag.add_to_tag(owner, &1, info)
    Tag.all owner
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

  @spec tag_task({Serum.Tag.t, MapSet.t}, String.t, pid) :: :ok

  def tag_task({tag, post_set}, dest, owner) do
    Process.link owner
    tagdir = "#{dest}tags/#{tag.name}/"
    fmt = ProjectInfo.get owner(), :list_title_tag
    title = fmt |> :io_lib.format([tag.name]) |> IO.iodata_to_binary
    posts = post_set |> MapSet.to_list |> Enum.sort(&(&1.file > &2.file))
    File.mkdir_p! tagdir
    save_list "#{tagdir}index.html", title, posts
  end

  @spec save_list(String.t, String.t, [Serum.PostInfo.t]) :: :ok

  defp save_list(path, title, posts) do
    template = BuildData.get owner(), "template", "list"
    html =
      template
      |> Renderer.render([header: title, posts: posts])
      |> Renderer.genpage([page_title: title], owner())
    fwrite path, html
    IO.puts "  GEN  #{path}"
    :ok
  end
end
