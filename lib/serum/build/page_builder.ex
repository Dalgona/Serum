defmodule Serum.Build.PageBuilder do
  @moduledoc """
  This module contains functions for building pages sequentially or parallelly.
  """

  alias Serum.Error
  alias Serum.Build
  alias Serum.Build.Renderer

  @type pageinfo :: %Serum.Pageinfo{}

  @spec run(String.t, String.t, Build.build_mode) :: Error.result
  def run(src, dest, mode) do
    template = Serum.get_data("template_page")
    info = Serum.get_data(:pageinfo)
    result = launch(mode, src, dest, info, template)
    case Enum.filter(result, &(&1 != :ok)) do
      [] -> :ok
      errors when is_list(errors) -> {:error, :child_tasks, errors}
    end
  end

  @spec launch(Build.build_mode, String.t, String.t, pageinfo, Build.compiled_template)
    :: [Error.result]
  defp launch(:parallel, src, dest, info, template) do
    info
    |> Enum.map(&(Task.async __MODULE__, :page_task, [src, dest, &1, template]))
    |> Enum.map(&Task.await&1)
  end

  defp launch(:sequential, src, dest, info, template) do
    info
    |> Enum.map(&(page_task src, dest, &1, template))
  end

  @spec page_task(String.t, String.t, pageinfo, Build.compiled_template)
    :: Error.result
  def page_task(src, dest, info, template) do
    srcname = "#{src}pages/#{info.name}.#{info.type}"
    dstname = "#{dest}#{info.name}.html"

    subdir = get_subdir(info.name)
    if subdir != "", do: File.mkdir_p!("#{dest}#{subdir}")

    try do
      html = srcname
             |> File.read!
             |> render(info.type, info.title, template)
      File.open!(dstname, [:write, :utf8], &(IO.write(&1, html)))
      IO.puts "  GEN  #{srcname} -> #{dstname}"
      :ok
    rescue
      e in File.Error ->
        {:error, :file_error, {Exception.message(e), srcname, 0}}
      e in Serum.PageTypeError ->
        {:error, :invalid_page_type, {Exception.message(e), srcname, 0}}
    end
  end

  @spec render(String.t, String.t, String.t, Build.compiled_template) :: String.t
  @raises [Serum.PageTypeError]
  defp render(md, "md", title, template), do:
    template
    |> Renderer.render([contents: Earmark.to_html(md)])
    |> Renderer.genpage([page_title: title])

  defp render(html, "html", title, template), do:
    template
    |> Renderer.render([contents: html])
    |> Renderer.genpage([page_title: title])

  defp render(_raw, type, _title, _template), do:
    raise Serum.PageTypeError, type: type

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
