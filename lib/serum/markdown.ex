defmodule Serum.Markdown do
  @moduledoc """
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
    |> Earmark.as_html!()
    |> process_links(proj.base_url)
  end

  @spec process_links(binary(), binary()) :: binary()
  defp process_links(data, base_url) do
    replace = &Regex.replace(&2, &1, &3)

    data
    |> replace.(@re_media, fn _, attr, val ->
      make_html_attr(attr, Path.join([base_url, "media", val]))
    end)
    |> replace.(@re_page, fn _, attr, val ->
      make_html_attr(attr, Path.join([base_url, val <> ".html"]))
    end)
    |> replace.(@re_post, fn _, attr, val ->
      make_html_attr(attr, Path.join([base_url, "posts", val <> ".html"]))
    end)
  end

  @spec make_html_attr(binary(), binary()) :: binary()
  defp make_html_attr(attr, value) do
    <<attr::binary, "=\"", value::binary, "\"">>
  end
end
