defmodule Serum.BuildPass2.PageBuilder do
  @moduledoc """
  This module contains functions for building pages sequentially or parallelly.
  """

  import Serum.Util
  alias Serum.Error
  alias Serum.Build
  alias Serum.BuildPass2.Renderer
  alias Serum.PageInfo

  @type state :: Build.state

  @async_opt [max_concurrency: System.schedulers_online * 10]

  @doc "Starts building pages in the `/path/to/project/pages` directory."
  @spec run(Build.mode, state) :: Error.result

  def run(mode, state) do
    result = launch mode, state.page_info, state
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
    {type, destpath} = get_type_and_destpath srcpath, state
    case File.open srcpath, [:read, :utf8] do
      {:ok, file} ->
        _ = IO.read file, :line
        data = IO.read file, :all
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

  @spec get_type_and_destpath(binary, state) :: {binary, binary}

  defp get_type_and_destpath(srcpath, state) do
    [type|temp] = srcpath |> String.split(".") |> Enum.reverse
    destpath =
      temp
      |> Enum.reverse
      |> Enum.join(".")
      |> String.replace_prefix("#{state.src}pages/", state.dest)
      |> Kernel.<>(".html")
    {type, destpath}
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
end
