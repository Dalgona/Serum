defmodule Serum.Renderer do
  @moduledoc """
  This module provides functions for rendering pages into HTML.
  """

  import Serum.Util
  alias Serum.Error
  alias Serum.GlobalBindings
  alias Serum.Build
  alias Serum.Template

  @type state :: Build.state

  @re_media ~r/(?<type>href|src)="(?:%|%25)media:(?<url>[^"]*)"/
  @re_post ~r/(?<type>href|src)="(?:%|%25)post:(?<url>[^"]*)"/
  @re_page ~r/(?<type>href|src)="(?:%|%25)page:(?<url>[^"]*)"/

  @doc """
  Renders contents into a complete HTML page.

  `stub_ctx` is a list of variable bindings which is fed into
  `templates/<template_name>.html.eex` template file, and `page_ctx` is a list
  of variable bindings which is then fed into `templates/base.html.eex` template
  file.
  """
  @spec render(binary, keyword, keyword, state) :: Error.result(binary)

  # render full page
  def render(template_name, stub_ctx, page_ctx, state) do
    proj = state.project_info
    global_bindings = GlobalBindings.as_keyword()
    case render_fragment Template.get(template_name), stub_ctx do
      {:ok, stub} ->
        contents = process_links stub, proj.base_url
        ctx = [contents: contents] ++ page_ctx
        render_fragment Template.get("base"), ctx ++ global_bindings
      error -> error
    end
  end

  @doc """
  Renders contents into a (partial) HTML stub.
  """
  @spec render_fragment(Template.t(), keyword()) :: Error.result(binary())
  def render_fragment(template, bindings) do
    global_bindings = GlobalBindings.as_keyword()
    bindings2 = Keyword.merge(bindings, global_bindings, fn _k, v, _ -> v end)
    {html, _} = Code.eval_quoted template.ast, bindings2
    {:ok, html}
  rescue
    e in CompileError ->
      {:error, {e.description, template.file, e.line}}
    e ->
      {:error, {Exception.message(e), template.file, 0}}
  end

  @spec process_links(binary, binary) :: binary
  def process_links(text, base) do
    text
    |> regex_replace(@re_media, ~s(\\1="#{base}media/\\2"))
    |> regex_replace(@re_page, ~s(\\1="#{base}\\2.html"))
    |> regex_replace(@re_post, ~s(\\1="#{base}posts/\\2.html"))
  end

  @spec regex_replace(binary, Regex.t, binary) :: binary
  defp regex_replace(text, pattern, replacement) do
    Regex.replace pattern, text, replacement
  end
end
