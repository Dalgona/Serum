defmodule Serum.Build.PageGenerator do
  @moduledoc false

  _moduledocp = "A module responsible for rendering complete HTML pages."

  import Serum.IOProxy, only: [put_msg: 2]
  alias Serum.Fragment
  alias Serum.Plugin
  alias Serum.Renderer
  alias Serum.Result
  alias Serum.Template
  alias Serum.Template.Storage, as: TS

  @spec run([Fragment.t()]) :: Result.t([Serum.File.t()])
  def run(fragments) do
    put_msg(:info, "Generating complete HTML pages...")

    template = TS.get("base", :template)

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
