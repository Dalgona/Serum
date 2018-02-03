defmodule Serum.Build.Pass2.PageBuilder do
  @moduledoc """
  During pass 2, PageBuilder does the following:

  1. Reads each page source file and produces HTML code according to the format:
      * If the source format is markdown, converts the soruce into HTML using
        Earmark.
      * If the source format is HTML, passes its contents as is.
      * If the source format is HTML with EEx, compiles the template and
        processes using `Serum.TemplateLoader.compile_template/2` function.
  2. Renders the full page using `Serum.Renderer.render/4` function.
  3. Saves the rendered page to the output directory.
  """

  import Serum.Util
  alias Serum.Error
  alias Serum.Build
  alias Serum.HeaderParser
  alias Serum.Page
  alias Serum.Renderer
  alias Serum.TemplateLoader

  @type state :: Build.state

  @async_opt [max_concurrency: System.schedulers_online * 10]

  @doc "Starts the second pass of PageBuilder."
  @spec run(Build.mode, state) :: Error.result

  def run(mode, state) do
    pages = state.site_ctx[:pages]
    create_dir pages, state.project_info.src, state.project_info.dest
    result = launch mode, pages, state
    Error.filter_results result, :page_builder
  end

  @spec launch(Build.mode, [Page.t], state) :: [Error.result]

  defp launch(:parallel, files, state) do
    files
    |> Task.async_stream(__MODULE__, :page_task, [state], @async_opt)
    |> Enum.map(&(elem &1, 1))
  end

  defp launch(:sequential, files, state) do
    files |> Enum.map(&page_task(&1, state))
  end

  @spec create_dir([Page.t], binary(), binary()) :: :ok

  defp create_dir(pages, src, dest) do
    page_dir = src == "." && "pages" || Path.join(src, "pages")
    pages
    |> Stream.map(&Path.dirname(&1.file))
    |> Stream.uniq()
    |> Stream.reject(& &1 == page_dir)
    |> Stream.map(&Path.relative_to(&1, page_dir))
    |> Stream.map(&Path.absname(&1, dest))
    |> Enum.each(fn dir ->
      File.mkdir_p! dir
      msg_mkdir dir
    end)
  end

  @doc false
  @spec page_task(Page.t, state) :: Error.result

  def page_task(page, state) do
    srcpath = page.file
    destpath = page.output

    case Page.render(page, state) do
      {:ok, html} ->
        fwrite destpath, html
        msg_gen srcpath, destpath
      {:error, _} = error -> error
    end
  end
end
