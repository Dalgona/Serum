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
  alias Serum.Page

  @doc "Starts the second pass of PageBuilder."
  @spec run([Page.t()], map()) :: Result.t()

  def run(pages, proj) do
    result = launch(pages, proj)
    Result.aggregate_values(result, :page_builder)
  end

  @spec launch([Page.t()], map()) :: [Result.t(Fragment.t())]
  defp launch(pages, proj) do
    pages
    |> Task.async_stream(Page, :to_fragment, [proj])
    |> Enum.map(&elem(&1, 1))
  end
end
