defmodule Serum.Renderer do
  @moduledoc """
  This module provides functions for rendering pages into HTML.
  """

  require Serum.Util
  import Serum.Util
  alias Serum.Error
  alias Serum.Build

  @type state :: Build.state

  @re_media ~r/(?<type>href|src)="(?:%|%25)media:(?<url>[^"]*)"/
  @re_old_post ~r/(?<type>href|src)="(?:%|%25)posts:(?<url>[^"]*)"/
  @re_old_page ~r/(?<type>href|src)="(?:%|%25)pages:(?<url>[^"]*)"/
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
    %{project_info: proj,
      templates: templates} = state
    site_ctx = state.site_ctx
    page_template = templates[template_name]
    base_template = templates["base"]
    tmp = Keyword.merge(stub_ctx, site_ctx, fn _k, v, _ -> v end)
    case render_stub page_template, tmp, template_name do
      {:ok, stub} ->
        contents = process_links stub, proj.base_url
        ctx = [contents: contents] ++ page_ctx
        render_stub base_template, ctx ++ site_ctx, "base"
      error -> error
    end
  end

  @doc """
  Renders contents into a (partial) HTML stub.
  """
  @spec render_stub(Build.template_ast, keyword, binary) :: Error.result(binary)

  def render_stub(template, context, name \\ "")

  def render_stub(nil, _ctx, name) do
    filename = to_filename name
    {:error, {"template was not compiled successfully", filename, 0}}
  end

  def render_stub(template, context, name) do
    filename = to_filename name
    try do
      {html, _} = Code.eval_quoted template, context
      {:ok, html}
    rescue
      e in CompileError ->
        {:error, {e.description, filename, e.line}}
      e ->
        {:error, {Exception.message(e), filename, 0}}
    end
  end

  @spec to_filename(binary) :: binary

  defp to_filename(name) do
    case name do
      "" -> "nofile"
      s when is_binary(s) -> s <> ".html.eex"
      _ -> "nofile"
    end
  end

  @spec process_links(binary, binary) :: binary

  defp process_links(text, base) do
    if Regex.match? @re_old_page, text do
      warn "\"%pages:\" notation is deprecated, and will be removed in the "
        <> "future release. Please use \"%page:\" instead"
    end
    if Regex.match? @re_old_post, text do
      warn "\"%posts:\" notation is deprecated, and will be removed in the "
        <> "future release. Please use \"%post:\" instead"
    end
    text
    |> regex_replace(@re_media, ~s(\\1="#{base}media/\\2"))
    |> regex_replace(@re_old_page, ~s(\\1="#{base}\\2.html"))
    |> regex_replace(@re_old_post, ~s(\\1="#{base}posts/\\2.html"))
    |> regex_replace(@re_page, ~s(\\1="#{base}\\2.html"))
    |> regex_replace(@re_post, ~s(\\1="#{base}posts/\\2.html"))
  end

  @spec regex_replace(binary, Regex.t, binary) :: binary

  defp regex_replace(text, pattern, replacement) do
    Regex.replace pattern, text, replacement
  end
end
