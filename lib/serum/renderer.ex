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
    assigns = [assigns: bindings ++ GlobalBindings.as_keyword()]
    {html, _} = Code.eval_quoted(template.ast, assigns, file: template.file.src)

    Result.return(html)
  rescue
    e in [CompileError, SyntaxError, TokenMissingError] ->
      Result.fail(Exception, [e, __STACKTRACE__], file: template.file, line: e.line)

    e ->
      Result.fail(Exception, [e, __STACKTRACE__], file: template.file)
  end
end
