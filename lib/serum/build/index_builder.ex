defmodule Serum.Build.IndexBuilder do
  @moduledoc """
  This module contains functions for generating index pages of blog posts.
  """

  alias Serum.Build
  alias Serum.Build.Renderer

  @spec run(String.t, String.t, Build.build_mode) :: any
  def run(_src, dest, mode) do
    dstdir = "#{dest}posts/"

    infolist = Serum.PostInfoStorage
           |> Agent.get(&(&1))
           |> Enum.sort_by(&(&1.file))

    IO.puts "Generating posts index..."
    save_list("#{dstdir}index.html", "All Posts", Enum.reverse(infolist))

    tagmap = generate_tagmap infolist
    Enum.each launch_tag(mode, tagmap, dest), &Task.await&1
  end

  @spec generate_tagmap([%Serum.Postinfo{}]) :: map
  defp generate_tagmap(infolist) do
    Enum.reduce infolist, %{}, fn m, a ->
      tmp = Enum.reduce m.tags, %{}, &(Map.put &2, &1, (Map.get &2, &1, []) ++ [m])
      Map.merge a, tmp, fn _, u, v -> MapSet.to_list(MapSet.new u ++ v) end
    end
  end

  @spec launch_tag(Build.build_mode, map, String.t) :: [Task.t]
  defp launch_tag(:parallel, tagmap, dir) do
    tagmap
    |> Enum.map(&(Task.async __MODULE__, :tag_task, [dir, &1]))
  end

  defp launch_tag(:sequential, tagmap, dir) do
    tagmap
    |> Enum.each(&(tag_task dir, &1))
    []
  end

  @spec tag_task(String.t, {map, [%Serum.Postinfo{}]}) :: :ok
  def tag_task(dest, {k, v}) do
    tagdir = "#{dest}tags/#{k.name}/"
    pt = "Posts Tagged \"#{k.name}\""
    posts = v |> Enum.sort(&(&1.file > &2.file))
    File.mkdir_p! tagdir
    save_list("#{tagdir}index.html", pt, posts)
  end

  @spec save_list(String.t, String.t, [%Serum.Postinfo{}]) :: :ok
  defp save_list(path, title, posts) do
    File.open!(path, [:write, :utf8], fn device ->
      template = Serum.get_data("template_list")
      html = template
             |> Renderer.render([header: title, posts: posts])
             |> Renderer.genpage([page_title: title])
      IO.write device, html
    end)
    IO.puts "  GEN  #{path}"
  end
end
