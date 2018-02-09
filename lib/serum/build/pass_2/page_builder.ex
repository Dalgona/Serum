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

  alias Serum.Result
  alias Serum.Fragment
  alias Serum.Build
  alias Serum.Page

  @doc "Starts the second pass of PageBuilder."
  @spec run(Build.mode, [Page.t()], map()) :: Result.t()

  def run(mode, pages, proj) do
    result = launch mode, pages, proj
    Result.aggregate_values result, :page_builder
  end

  @spec launch(Build.mode, [Page.t], map()) :: [Result.t(Fragment.t())]
  defp launch(mode, pages, proj)

  defp launch(:parallel, pages, proj) do
    pages
    |> Task.async_stream(Page, :to_fragment, [proj])
    |> Enum.map(&(elem &1, 1))
  end

  defp launch(:sequential, pages, proj) do
    pages |> Enum.map(&Page.to_fragment(&1, proj))
  end
end
