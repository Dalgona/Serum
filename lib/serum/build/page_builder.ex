defmodule Serum.Build.PageBuilder do
  @moduledoc """
  This module contains functions for building pages sequentially or parallelly.
  """

  alias Serum.Build
  alias Serum.Build.Renderer

  @spec run(String.t, String.t, Build.build_mode) :: any
  def run(src, dest, mode) do
    template = Serum.get_data("template_page")
    info = Serum.get_data(:pageinfo)
    launch(src, dest, info, template, mode)
  end

  # FIXME: Inconsistent argument order (with Serum.PostBuilder.launch_post/4)
  # FIXME: Inconsistent behavior (with Serum.PostBuilder.launch_post/4)
  @spec launch(String.t, String.t, Serum.compiled_template, Build.build_mode) :: any
  defp launch(src, dest, info, template, :parallel), do:
    info
    |> Enum.map(&(Task.async __MODULE__, :page_task, [src, dest, &1, template]))
    |> Enum.each(&(Task.await &1))

  defp launch(src, dest, info, template, :sequential), do:
    info
    |> Enum.each(&(page_task src, dest, &1, template))

  @spec page_task(String.t, String.t, %Serum.Pageinfo{}, Build.compiled_string) :: any
  def page_task(src, dest, info, template) do
    srcname = "#{src}pages/#{info.name}.#{info.type}"
    dstname = "#{dest}#{info.name}.html"

    subdir = get_subdir(info.name)
    if subdir != "", do: File.mkdir_p!("#{dest}#{subdir}")

    html = srcname
           |> File.read!
           |> render(info.type, info.title, template)
    File.open!(dstname, [:write, :utf8], &(IO.write(&1, html)))

    IO.puts "  GEN  #{srcname} -> #{dstname}"
  end

  @spec render(String.t, String.t, String.t, Build.compiled_string) :: String.t
  defp render(md, "md", title, template), do:
    template
    |> Renderer.render([contents: Earmark.to_html(md)])
    |> Renderer.genpage([page_title: title])

  defp render(html, "html", title, template), do:
    template
    |> Renderer.render([contents: html])
    |> Renderer.genpage([page_title: title])

  @spec get_subdir(String.t) :: String.t
  defp get_subdir(path) do
    [_|subdir] = path |> String.split("/") |> Enum.reverse
    case subdir do
      []  -> ""
      [x] -> x <> "/"
      l   -> (l |> Enum.reverse |> Enum.join("/")) <> "/"
    end
  end
end
