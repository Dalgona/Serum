defmodule Serum.Build.PageBuilder do
  alias Serum.Build.Renderer

  def run(src, dest, mode) do
    template = Agent.get Global, &(Map.get &1, "template_page")
    info = Agent.get Global, &(Map.get &1, :pageinfo)

    case mode do
      :parallel ->
        info
        |> Enum.map(&(Task.async __MODULE__, :page_task, [src, dest, &1, template]))
        |> Enum.each(&(Task.await &1))
      _ ->
        info
        |> Enum.each(&(page_task src, dest, &1, template))
    end
  end

  def page_task(src, dest, info, template) do
    srcname = "#{src}pages/#{info.name}.#{info.type}"
    dstname = "#{dest}#{info.name}.html"

    txt = File.read! srcname
    html = render(txt, info, template)

    subdir = get_subdir info.name
    if get_subdir(info.name) != "", do: File.mkdir_p! "#{dest}#{subdir}"
    File.open! dstname, [:write, :utf8], fn device ->
      IO.write device, html
    end

    IO.puts "  GEN  #{srcname} -> #{dstname}"
  end

  defp render(txt, info, template) do
    html = case info.type do
      "md" -> Earmark.to_html txt
      "html" -> txt
    end
    template
    |> Renderer.render([contents: html])
    |> Renderer.genpage([page_title: info.title])
  end

  defp get_subdir(path) do
    [_|subdir] = path |> String.split("/") |> Enum.reverse
    case subdir do
      [] -> ""
      [x] -> x <> "/"
      x when is_list x -> (x |> Enum.reverse |> Enum.join("/")) <> "/"
    end
  end
end
