defmodule Serum.Build.Renderer do
  @moduledoc """
  This module provides functions for rendering pages into complete HTML files.
  """

  alias Serum.Build

  @re_media ~r/(?<type>href|src)="%25media:(?<url>[^"]*)"/
  @re_posts ~r/(?<type>href|src)="%25posts:(?<url>[^"]*)"/
  @re_pages ~r/(?<type>href|src)="%25pages:(?<url>[^"]*)"/

  @spec genpage(String.t, keyword) :: String.t
  def genpage(contents, ctx) do
    base = Serum.get_data("template", "base")
    contents = process_links(contents)
    binding = [contents: contents, navigation: Serum.get_data("navstub")]
    render(base, ctx ++ binding)
  end

  @spec render(Build.compiled_template, keyword) :: String.t
  def render(template, context) do
    {html, _} = Code.eval_quoted(template, context)
    html
  end

  @spec process_links(String.t) :: String.t
  defp process_links(text) do
    base = Serum.get_data("proj", "base_url")
    text = Regex.replace(@re_media, text, ~s(\\1="#{base}media/\\2"))
    text = Regex.replace(@re_posts, text, ~s(\\1="#{base}posts/\\2.html"))
    text = Regex.replace(@re_pages, text, ~s(\\1="#{base}\\2.html"))
    text
  end
end
