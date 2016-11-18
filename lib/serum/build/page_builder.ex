defmodule Serum.Build.PageBuilder do
  @moduledoc """
  This module contains functions for building pages sequentially or parallelly.
  """

  alias Serum.Error
  alias Serum.Build
  alias Serum.Build.Renderer

  @doc """
  Starts building pages in the `/path/to/project/pages` directory.
  """
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

  @doc """
  Defines the individual page build task.
  """
  @spec page_task(String.t, String.t, String.t) :: Error.result

  def page_task(src, dest, fname) do
    [type|name] = fname |> String.split(".") |> Enum.reverse
    name = name |> Enum.reverse |> Enum.join(".")
    destname = String.replace_prefix(name, "#{src}pages/", dest) <> ".html"
    template = Serum.get_data("template", "page")

    try do
      html =
        with {title, lines} <- extract_header(fname) do
          raw = lines |> Enum.join("\n")
          render(type, raw, title, template)
        end
      File.open!(destname, [:write, :utf8], &IO.write(&1, html))
      IO.puts "  GEN  #{fname} -> #{destname}"
      :ok
    rescue
      e in File.Error ->
        {:error, :file_error, {Exception.message(e), fname, 0}}
      e in Serum.PageTypeError ->
        {:error, :invalid_page_type, {Exception.message(e), fname, 0}}
      e in Serum.PageError ->
        {:error, :post_error, {Exception.message(e), fname, 0}}
    end
  end

  @docp """
  Extracts the title and contents from a given page source file.
  """
  @spec extract_header(String.t) :: {String.t, String.t}
  @raises [File.Error, Serum.PageError]

  defp extract_header(fname) do
    try do
      ["# " <> title|lines] =
        fname |> File.read!  |> String.split("\n")
      {title, lines}
    rescue
      _ in MatchError ->
        raise Serum.PageError, reason: :header, path: fname
    end
  end

  @docp """
  Renders a page into an complete HTML format.
  """
  @spec render(String.t, String.t, String.t, Build.compiled_template)
    :: String.t
  @raises [Serum.PageTypeError]

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

