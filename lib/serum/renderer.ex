defmodule Serum.Renderer do
  @moduledoc false

  _moduledocp = "This module provides functions for rendering pages into HTML."

  require Serum.Result, as: Result
  alias Serum.GlobalBindings
  alias Serum.Template

  @doc """
  Renders contents into a (partial) HTML stub.
  """
  @spec render_fragment(Template.t(), keyword()) :: Result.t(binary())
  def render_fragment(template, bindings) do
    assigns = bindings ++ GlobalBindings.as_keyword()
    {html, _} = Code.eval_quoted(template.ast, assigns: assigns)

    Result.return(html)
  rescue
    e -> Result.fail(Exception, [e, __STACKTRACE__], file: %Serum.File{src: template.file})
  end
end
