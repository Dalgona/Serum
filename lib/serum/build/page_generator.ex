defmodule Serum.Build.PageGenerator do
  @moduledoc false

  _moduledocp = "A module responsible for rendering complete HTML pages."

  require Serum.V2.Result, as: Result
  import Serum.V2.Console, only: [put_msg: 2]
  alias Serum.Plugin.Client, as: PluginClient
  alias Serum.Renderer
  alias Serum.Template.Storage, as: TS
  alias Serum.V2
  alias Serum.V2.Error
  alias Serum.V2.Fragment
  alias Serum.V2.Template

  @spec run([Fragment.t()]) :: Result.t([V2.File.t()])
  def run(fragments) do
    put_msg(:info, "Generating complete HTML pages...")

    Result.run do
      template <- TS.get("base", :template)
      files <- render_pages(fragments, template)

      PluginClient.rendered_pages(files)
    end
  end

  @spec render_pages([Fragment.t()], Template.t()) :: Result.t([V2.File.t()])
  defp render_pages(fragments, template) do
    fragments
    |> Task.async_stream(&render_page(&1, template))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate("failed to render HTML pages:")
  end

  @spec render_page(Fragment.t(), Template.t()) :: Result.t(V2.File.t())
  defp render_page(fragment, template) do
    assigns = [
      page: fragment.metadata,
      contents: fragment.data
    ]

    case Renderer.render_fragment(template, assigns) do
      {:ok, html} ->
        Result.return(%V2.File{
          src: fragment.source && fragment.source.src,
          dest: fragment.dest,
          in_data: nil,
          out_data: html
        })

      {:error, %Error{}} = error ->
        error
    end
  end
end
