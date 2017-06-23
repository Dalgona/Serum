defmodule Serum.Build.Pass2.PageBuilder do
  @moduledoc """
  This module contains functions for building pages sequentially or parallelly.
  """

  import Serum.Util
  alias Serum.Error
  alias Serum.Build
  alias Serum.HeaderParser
  alias Serum.PageInfo
  alias Serum.Renderer
  alias Serum.TemplateLoader

  @type state :: Build.state

  @async_opt [max_concurrency: System.schedulers_online * 10]

  @doc "Starts building pages in the `/path/to/project/pages` directory."
  @spec run(Build.mode, state) :: Error.result

  def run(mode, state) do
    result = launch mode, state.site_ctx[:pages], state
    Error.filter_results result, :page_builder
  end

  # Launches individual page build tasks if the program is running in `parallel`
  # mode, otherwise performs the tasks one by one.
  @spec launch(Build.mode, [PageInfo.t], state) :: [Error.result]

  defp launch(:parallel, files, state) do
    files
    |> Task.async_stream(__MODULE__, :page_task, [state], @async_opt)
    |> Enum.map(&(elem &1, 1))
  end

  defp launch(:sequential, files, state) do
    files |> Enum.map(&page_task(&1, state))
  end

  @doc "Defines the individual page build task."
  @spec page_task(PageInfo.t, state) :: Error.result

  def page_task(info, state) do
    srcpath = info.file
    {type, destpath} = PageInfo.get_type_and_destpath srcpath, state
    destpath = state.dest <> destpath
    case File.open srcpath, [:read, :utf8] do
      {:ok, file} ->
        file = HeaderParser.skip_header file
        data = IO.read file, :all
        File.close file
        case render_page type, data, info.title, state do
          {:ok, html} ->
            fwrite destpath, html
            IO.puts "  GEN  #{srcpath} -> #{destpath}"
          {:error, _, _} = error -> error
        end
      {:error, reason} ->
        {:error, :file_error, {reason, srcpath, 0}}
    end
  end

  # Renders a page into a complete HTML format.
  @spec render_page(binary, binary, binary, state) :: Error.result(binary)

  defp render_page("md", md, title, state) do
    html = Earmark.to_html md
    Renderer.render "page", [contents: html], [page_title: title], state
  end

  defp render_page("html", html, title, state) do
    Renderer.render "page", [contents: html], [page_title: title], state
  end

  defp render_page("eex", html, title, state) do
    with {:ok, ast} <- TemplateLoader.compile_template(html, state),
         {:ok, html} <- Renderer.render_stub(ast, state.site_ctx, "")
    do
      Renderer.render "page", [contents: html], [page_title: title], state
    else
      {:error, _, _} = error -> error
    end
  end
end
