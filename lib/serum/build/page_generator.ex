defmodule Serum.Build.PageGenerator do
  @moduledoc """
  A module responsible for rendering complete HTML pages.
  """

  alias Serum.Fragment
  alias Serum.Plugin
  alias Serum.Renderer
  alias Serum.Result
  alias Serum.Template

  @spec run([Fragment.t()], Template.t()) :: Result.t([Serum.File.t()])
  def run(fragments, template) do
    IO.puts("Generating complete HTML pages...")

    fragments
    |> Task.async_stream(&render(&1, template))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate_values(:page_generator)
  end

  @spec render(Fragment.t(), Template.t()) :: Result.t(Serum.File.t())
  defp render(fragment, template) do
    assigns = [
      page: fragment.metadata,
      contents: fragment.data
    ]

    case Renderer.render_fragment(template, assigns) do
      {:ok, html} ->
        file = %Serum.File{
          src: fragment.file,
          dest: fragment.output,
          in_data: nil,
          out_data: html
        }

        Plugin.rendered_page(file)

      {:error, _} = error ->
        error
    end
  end
end
