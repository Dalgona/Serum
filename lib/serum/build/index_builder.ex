defmodule Serum.Build.IndexBuilder do
  @moduledoc """
  This module contains functions for generating index pages of blog posts.
  """

  import Serum.Util
  alias Serum.Error
  alias Serum.Build
  alias Serum.Build.Renderer

  @default_title_all "All Posts"
  @default_title_tag "Posts Tagged ~s"

  @spec run(String.t, String.t, Build.build_mode) :: Error.result

  def run(_src, dest, mode) do
    dstdir = "#{dest}posts/"
    if File.exists? dstdir do
      infolist = Serum.PostInfoStorage
            |> Agent.get(&(&1))
            |> Enum.sort_by(&(&1.file))
      title = Serum.get_data("proj", "list_title_all") || @default_title_all

      IO.puts "Generating posts index..."
      save_list "#{dstdir}index.html", title, Enum.reverse(infolist)

      tags = update_tags infolist
      result = launch_tag mode, tags, dest
      Error.filter_results result, :index_builder
    else
      {:error, :file_error, {:enoent, dstdir, 0}}
    end
  end

  @spec update_tags([Serum.Postinfo.t]) :: :ok

  defp update_tags(infolist) do
    Agent.update Serum.TagStorage, fn _ -> %{} end
    Enum.each infolist, fn info ->
      tags = info.tags
      Enum.each tags, fn tag ->
        mapset = Agent.get Serum.TagStorage, &Map.get(&1, tag, MapSet.new())
        mapset = MapSet.put mapset, info
        Agent.update Serum.TagStorage, &Map.put(&1, tag, mapset)
      end
    end
    Agent.get Serum.TagStorage, &(&1)
  end

  @spec launch_tag(Build.build_mode, map, String.t) :: [Task.t]

  defp launch_tag(:parallel, tagmap, dir) do
    tagmap
    |> Task.async_stream(__MODULE__, :tag_task, [dir])
    |> Enum.map(&elem(&1, 1))
  end

  defp launch_tag(:sequential, tagmap, dir) do
    tagmap
    |> Enum.map(&tag_task(dir, &1))
  end

  @spec tag_task({Serum.Tag.t, MapSet.t}, String.t) :: :ok

  def tag_task({tag, post_set}, dest) do
    tagdir = "#{dest}tags/#{tag.name}/"
    fmt = Serum.get_data("proj", "list_title_tag") || @default_title_tag
    title = fmt |> :io_lib.format([tag.name]) |> IO.iodata_to_binary
    posts = post_set |> MapSet.to_list |> Enum.sort(&(&1.file > &2.file))
    File.mkdir_p! tagdir
    save_list "#{tagdir}index.html", title, posts
  end

  @spec save_list(String.t, String.t, [Serum.Postinfo.t]) :: :ok

  defp save_list(path, title, posts) do
    template = Serum.get_data "template", "list"
    html =
      template
      |> Renderer.render([header: title, posts: posts])
      |> Renderer.genpage([page_title: title])
    fwrite path, html
    IO.puts "  GEN  #{path}"
    :ok
  end
end
