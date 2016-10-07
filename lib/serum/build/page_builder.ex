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
    txt = File.read!("#{src}pages/#{info.name}.#{info.type}")
    html = case info.type do
      "md" -> Earmark.to_html txt
      "html" -> txt
    end
    html = template
           |> Renderer.render([contents: html])
           |> Renderer.genpage([page_title: info.title])
    [_|subdir] = info.name |> String.split("/") |> Enum.reverse
    subdir = case subdir do
      [] -> ""
      [x] -> x <> "/"
      [_|_] -> (subdir |> Enum.reverse |> Enum.join("/")) <> "/"
    end
    if subdir != "", do: File.mkdir_p! "#{dest}#{subdir}"
    File.open! "#{dest}#{info.name}.html", [:write, :utf8], fn device ->
      IO.write device, html
    end
    IO.puts "  GEN  #{src}pages/#{info.name}.#{info.type} -> #{dest}#{info.name}.html"
  end
end
