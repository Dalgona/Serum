defmodule Serum.Build.PageBuilder do
  alias Serum.Build.Renderer

  def run(src, dest, mode) do
    template = Serum.get_data("template_page")
    info = Serum.get_data(:pageinfo)
    launch(src, dest, info, template, mode)
  end

  defp launch(src, dest, info, template, :parallel), do:
    info
    |> Enum.map(&(Task.async __MODULE__, :page_task, [src, dest, &1, template]))
    |> Enum.each(&(Task.await &1))

  defp launch(src, dest, info, template, :sequential), do:
    info
    |> Enum.each(&(page_task src, dest, &1, template))

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

  defp render(md, "md", title, template), do:
    template
    |> Renderer.render([contents: Earmark.to_html(md)])
    |> Renderer.genpage([page_title: title])

  defp render(html, "html", title, template), do:
    template
    |> Renderer.render([contents: html])
    |> Renderer.genpage([page_title: title])

  defp get_subdir(path) do
    [_|subdir] = path |> String.split("/") |> Enum.reverse
    case subdir do
      []  -> ""
      [x] -> x <> "/"
      l   -> (l |> Enum.reverse |> Enum.join("/")) <> "/"
    end
  end
end
