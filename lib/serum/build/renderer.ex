defmodule Serum.Build.Renderer do
  @moduledoc """
  This module provides functions for rendering pages into complete HTML files.
  """

  alias Serum.Build

  @type state :: Build.state

  @re_media ~r/(?<type>href|src)="(?:%|%25)media:(?<url>[^"]*)"/
  @re_posts ~r/(?<type>href|src)="(?:%|%25)posts:(?<url>[^"]*)"/
  @re_pages ~r/(?<type>href|src)="(?:%|%25)pages:(?<url>[^"]*)"/

  @spec render(binary, keyword, keyword, state) :: binary

  # render full page
  def render(template_name, stub_ctx, page_ctx, state) do
    with %{project_info: proj, build_data: build_data} <- state do
      site_ctx = [
        site_name: proj.site_name, site_description: proj.site_description,
        author: proj.author, author_email: proj.author_email
      ]
      page_template = build_data["template__#{template_name}"]
      base_template = build_data["template__base"]
      nav_area      = build_data["navstub"]
      with {stub, _} <- Code.eval_quoted page_template, stub_ctx ++ site_ctx do
        contents = process_links stub, proj.base_url
        ctx = [{:contents, contents}, {:navigation, nav_area}|page_ctx]
        {html, _} = Code.eval_quoted base_template, ctx ++ site_ctx
        html
      end
    end
  end

  @spec render(Build.compiled_template, keyword) :: String.t

  def render(template, context) do
    {html, _} = Code.eval_quoted template, context
    html
  end

  @spec process_links(String.t, String.t) :: String.t

  def process_links(text, base) do
    text = Regex.replace @re_media, text, ~s(\\1="#{base}media/\\2")
    text = Regex.replace @re_posts, text, ~s(\\1="#{base}posts/\\2.html")
    text = Regex.replace @re_pages, text, ~s(\\1="#{base}\\2.html")
    text
  end
end
