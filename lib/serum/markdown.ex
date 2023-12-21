defmodule Serum.Markdown do
  @moduledoc false

  _moduledocp = """
  This module provides functions related to dealing with markdown data.
  """

  alias Serum.Project

  @re_media ~r/(?<type>href|src)="(?:%|%25)media:(?<url>[^"]*)"/
  @re_post ~r/(?<type>href|src)="(?:%|%25)post:(?<url>[^"]*)"/
  @re_page ~r/(?<type>href|src)="(?:%|%25)page:(?<url>[^"]*)"/

  @doc "Converts a markdown document into HTML."
  @spec to_html(binary(), Project.t()) :: binary()
  def to_html(markdown, proj) do
    markdown
    |> Earmark.as_html!(code_class_prefix: "lang-")
    |> process_links(proj.base_url)
  end

  @spec process_links(binary(), Project.t()) :: binary()
  defp process_links(data, proj) do
    data
    |> replace_media_links(proj)
    |> replace_page_links(proj)
    |> replace_post_links(proj)
  end

  @spec replace_media_links(binary(), Project.t()) :: binary()
  defp replace_media_links(data, proj) do
    Regex.replace(@re_media, data, fn _, attr, val ->
      make_html_attr(attr, Path.join([proj.base_url, "media", val]))
    end)
  end

  @spec replace_page_links(binary(), Project.t()) :: binary()
  defp replace_page_links(data, proj) do
    Regex.replace(@re_page, data, fn _, attr, val ->
      make_html_attr(attr, Path.join([proj.base_url, val <> ".html"]))
    end)
  end

  @spec replace_post_links(binary(), Project.t()) :: binary()
  defp replace_post_links(data, proj) do
    suffix = post_suffix(proj.pretty_urls)

    Regex.replace(@re_post, data, fn _, attr, val ->
      make_html_attr(attr, Path.join([proj.base_url, "posts", val <> suffix]))
    end)
  end

  @spec make_html_attr(binary(), binary()) :: binary()
  defp make_html_attr(attr, value) do
    <<attr::binary, "=\"", value::binary, "\"">>
  end

  @spec post_suffix(Project.pretty_urls()) :: binary()
  defp post_suffix(pretty_urls)
  defp post_suffix(true), do: ""
  defp post_suffix(:posts), do: ""
  defp post_suffix(_pretty_urls), do: ".html"
end
