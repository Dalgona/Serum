defmodule Serum.Renderer do
  @moduledoc false

  _moduledocp = "This module provides functions for rendering pages into HTML."

  require Serum.V2.Result, as: Result
  alias Serum.GlobalBindings
  alias Serum.V2.Template

  @doc """
  Renders contents into a (partial) HTML stub.
  """
  @spec render_fragment(Template.t(), keyword()) :: Result.t(binary())
  def render_fragment(template, bindings) do
    assigns = [assigns: bindings ++ GlobalBindings.as_keyword()]
    {html, _} = Code.eval_quoted(template.ast, assigns, file: template.source.src)

    Result.return(html)
  rescue
    e in [CompileError, SyntaxError, TokenMissingError] ->
      Result.fail(Exception: [e, __STACKTRACE__], file: template.source, line: e.line)

    e ->
      Result.fail(Exception: [e, __STACKTRACE__], file: template.source)
  end
end
