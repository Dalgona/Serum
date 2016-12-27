defmodule Serum.Build.PageBuilder do
  @moduledoc """
  This module contains functions for building pages sequentially or parallelly.
  """

  import Serum.Util
  alias Serum.Error
  alias Serum.Build
  alias Serum.Build.Renderer

  @typep header :: {String.t, [String.t]}

  @doc "Starts building pages in the `/path/to/project/pages` directory."
  @spec run(String.t, String.t, Build.build_mode) :: Error.result

  def run(src, dest, mode) do
    files = Serum.get_data("pages_file")
    result = launch(mode, src, dest, files)
    Error.filter_results(result, :page_builder)
  end

  @docp """
  Launches individual page build tasks if the program is running in `parallel`
  mode, otherwise performs the tasks one by one.
  """
  @spec launch(Build.build_mode, String.t, String.t, String.t)
    :: [Error.result]

  defp launch(:parallel, src, dest, files) do
    files
    |> Enum.map(&Task.async(__MODULE__, :page_task, [src, dest, &1]))
    |> Enum.map(&Task.await/1)
  end

  defp launch(:sequential, src, dest, files) do
    files
    |> Enum.map(&page_task(src, dest, &1))
  end

  @doc "Defines the individual page build task."
  @spec page_task(String.t, String.t, String.t) :: Error.result

  def page_task(src, dest, fname) do
    [type|name] = fname |> String.split(".") |> Enum.reverse
    name = name |> Enum.reverse |> Enum.join(".")
    destname = String.replace_prefix(name, "#{src}pages/", dest) <> ".html"
    template = Serum.get_data("template", "page")

    if type != "md" and type != "html" do
      {:error, :page_error, {:unsupported_type, fname, 0}}
    else
      case extract_header fname do
        {:ok, {title, rest}} ->
          raw = rest |> Enum.join("\n")
          html = render type, raw, title, template
          fwrite destname, html
          IO.puts "  GEN  #{fname} -> #{destname}"
          :ok
        error = {:error, _, _} ->
          error
      end
    end
  end

  @docp """
  Extracts the title and contents from a given page source file.
  """
  @spec extract_header(String.t) :: Error.result(header)

  defp extract_header(fname) do
    case File.read fname do
      {:ok, data} ->
        do_extract_header fname, data
      {:error, reason} ->
        {:error, :file_error, {reason, fname, 0}}
    end
  end

  @spec do_extract_header(String.t, String.t) :: Error.result(header)
  defp do_extract_header fname, data do
    [title|rest] = data |> String.split("\n")
    if String.starts_with?(title, "# ") do
      "# " <> title = title
      {:ok, {title, rest}}
    else
      {:error, :page_error, {:invalid_header, fname, 0}}
    end
  end

  @docp "Renders a page into an complete HTML format."
  @spec render(String.t, String.t, String.t, Build.compiled_template)
    :: String.t

  defp render("md", md, title, template) do
    template
    |> Renderer.render([contents: Earmark.to_html(md)])
    |> Renderer.genpage([page_title: title])
  end

  defp render("html", html, title, template) do
    template
    |> Renderer.render([contents: html])
    |> Renderer.genpage([page_title: title])
  end
end