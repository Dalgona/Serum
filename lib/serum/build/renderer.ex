defmodule Serum.Build.Renderer do
  @re_media ~r/(?<type>href|src)="%25media:(?<url>[^"]*)"/
  @re_posts ~r/(?<type>href|src)="%25posts:(?<url>[^"]*)"/
  @re_pages ~r/(?<type>href|src)="%25pages:(?<url>[^"]*)"/

  def process_links(text, proj) do
    base = Keyword.get(proj, :base_url)
    text = Regex.replace(@re_media, text, ~s(\\1="#{base}media/\\2"))
    text = Regex.replace(@re_posts, text, ~s(\\1="#{base}posts/\\2.html"))
    text = Regex.replace(@re_pages, text, ~s(\\1="#{base}\\2.html"))
    text
  end

  def genpage(contents, ctx) do
    proj = Serum.get_data(:proj)
    base = Serum.get_data("template_base")
    contents = process_links(contents, proj)
    render(base, proj ++ ctx ++ [contents: contents, navigation: Serum.get_data(:navstub)])
  end

  def render(template, assigns) do
    proj = Serum.get_data(:proj)
    {html, _} = Code.eval_quoted(template, [assigns: proj ++ assigns])
    html
  end
end
