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

      tagmap = generate_tagmap infolist
      Enum.each launch_tag(mode, tagmap, dest), &Task.await(&1)
    else
      {:error, :file_error, {:enoent, dstdir, 0}}
    end
  end

  @spec generate_tagmap([%Serum.Postinfo{}]) :: map
  defp generate_tagmap(infolist) do
    Enum.reduce infolist, %{}, fn m, a ->
      tmp =
        Enum.reduce m.tags, %{}, &(Map.put &2, &1, (Map.get &2, &1, []) ++ [m])
      Map.merge a, tmp, fn _, u, v -> MapSet.to_list(MapSet.new u ++ v) end
    end
  end

  @spec launch_tag(Build.build_mode, map, String.t) :: [Task.t]
  defp launch_tag(:parallel, tagmap, dir) do
    tagmap
    |> Enum.map(&Task.async(__MODULE__, :tag_task, [dir, &1]))
  end

  defp launch_tag(:sequential, tagmap, dir) do
    tagmap
    |> Enum.each(&tag_task(dir, &1))
    []
  end

  @spec tag_task(String.t, {map, [%Serum.Postinfo{}]}) :: :ok
  def tag_task(dest, {k, v}) do
    tagdir = "#{dest}tags/#{k.name}/"
    fmt = Serum.get_data("proj", "list_title_tag") || @default_title_tag
    title = fmt |> :io_lib.format([k.name]) |> IO.iodata_to_binary
    posts = v |> Enum.sort(&(&1.file > &2.file))
    File.mkdir_p! tagdir
    save_list "#{tagdir}index.html", title, posts
  end

  @spec save_list(String.t, String.t, [%Serum.Postinfo{}]) :: :ok
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
