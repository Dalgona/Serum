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

  require Serum.Util
  import Serum.Util
  alias Serum.Error
  alias Serum.Build
  alias Serum.HeaderParser
  alias Serum.PageInfo
  alias Serum.Renderer
  alias Serum.TemplateLoader

  @type state :: Build.state

  @async_opt [max_concurrency: System.schedulers_online * 10]

  @doc "Starts the second pass of PageBuilder."
  @spec run(Build.mode, state) :: Error.result

  def run(mode, state) do
    pages = state.site_ctx[:pages]
    create_dir pages, state
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

  @spec create_dir([PageInfo.t], state) :: :ok

  defp create_dir(pages, state) do
    page_dir = Path.join state.src, "pages"
    pages
    |> Stream.map(&Path.dirname(&1.file))
    |> Stream.uniq()
    |> Stream.reject(& &1 == page_dir)
    |> Stream.map(&Path.relative_to(&1, page_dir))
    |> Stream.map(&Path.absname(&1, state.dest))
    |> Enum.each(fn dir ->
      File.mkdir_p! dir
      msg_mkdir dir
    end)
  end

  @doc false
  @spec page_task(PageInfo.t, state) :: Error.result

  def page_task(info, state) do
    srcpath = info.file
    destpath = info.output
    case File.open srcpath, [:read, :utf8] do
      {:ok, file} ->
        file = HeaderParser.skip_header file
        data = IO.read file, :all
        File.close file
        new_state = Map.put state, :srcpath, srcpath
        case render_page info.type, data, info.title, new_state do
          {:ok, html} ->
            fwrite destpath, html
            msg_gen srcpath, destpath
          {:error, _} = error -> error
        end
      {:error, reason} ->
        {:error, {reason, srcpath, 0}}
    end
  end

  # Renders a page into a complete HTML format.
  @spec render_page(binary, binary, binary, state) :: Error.result(binary)

  defp render_page(".md", md, title, state) do
    html = Earmark.to_html md
    Renderer.render "page", [contents: html], [page_title: title], state
  end

  defp render_page(".html", html, title, state) do
    Renderer.render "page", [contents: html], [page_title: title], state
  end

  defp render_page(".html.eex", html, title, state) do
    with {:ok, ast} <- TemplateLoader.compile_template(html, state),
         {:ok, html} <- Renderer.render_stub(ast, state.site_ctx, "")
    do
      Renderer.render "page", [contents: html], [page_title: title], state
    else
      {:ct_error, msg, line} ->
        {:error, {msg, state.srcpath, line}}
      {:error, _} = error -> error
    end
  end
end
