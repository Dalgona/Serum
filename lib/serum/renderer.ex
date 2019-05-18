defmodule Serum.Renderer do
  @moduledoc false

  _moduledocp = "This module provides functions for rendering pages into HTML."

  alias Serum.GlobalBindings
  alias Serum.Result
  alias Serum.Template

  @doc """
  Renders contents into a (partial) HTML stub.
  """
  @spec render_fragment(Template.t(), keyword()) :: Result.t(binary())
  def render_fragment(template, bindings) do
    assigns = bindings ++ GlobalBindings.as_keyword()
    {html, _} = Code.eval_quoted(template.ast, assigns: assigns)
    {:ok, html}
  rescue
    e in CompileError ->
      {:error, {e.description, template.file, e.line}}

    e ->
      {:error, {Exception.message(e), template.file, 0}}
  end
end
