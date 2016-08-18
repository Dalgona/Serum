defmodule Serum.Build do
  @dowstr {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"}
  @monabbr {"", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
  @re_media ~r/(?<type>href|src)="%25media:(?<url>[^"]*)"/
  @re_posts ~r/(?<type>href|src)="%25posts:(?<url>[^"]*)"/
  @re_pages ~r/(?<type>href|src)="%25pages:(?<url>[^"]*)"/

  def compile_nav(proj, meta) do
    IO.puts "Compiling main navigation HTML stub..."
    template = Agent.get Global, &(Map.get &1, "template_nav")
    html = render template, proj ++ [pages: Enum.filter(meta, &(&1.menu))]
    Agent.update Global, &(Map.put &1, :navstub, html)
  end

  def build_pages(dir, proj, meta) do
    template = Agent.get Global, &(Map.get &1, "template_page")

    IO.puts "Cleaning pages..."
    File.ls!("#{dir}site/")
    |> Enum.filter(&(String.ends_with? &1, ".html"))
    |> Enum.each(&(File.rm_rf! "#{dir}site/#{&1}"))

    Enum.map(meta, fn x ->
      Task.async fn ->
        txt = File.read!("#{dir}pages/#{x.name}.#{x.type}")
        html = case x.type do
          "md" -> Earmark.to_html txt
          "html" -> txt
        end
        html = render(template, proj ++ [contents: html])
               |> genpage(proj ++ [page_title: x.title])
        File.open! "#{dir}site/#{x.name}.html", [:write, :utf8], fn device ->
          IO.write device, html
        end
        IO.puts "  GEN  #{dir}pages/#{x.name}.#{x.type} -> #{dir}site/#{x.name}.html"
      end
    end)
    |> Enum.each(&(Task.await &1))
  end

  def build_posts(dir, proj) do
    srcdir = "#{dir}posts/"
    dstdir = "#{dir}site/posts/"
    template_post = Agent.get Global, &(Map.get &1, "template_post")
    template_list = Agent.get Global, &(Map.get &1, "template_list")

    files = File.ls!(srcdir)
            |> Enum.filter(&(String.ends_with? &1, ".md"))
            |> Enum.map(&(String.replace &1, ~r/\.md$/, ""))
            |> Enum.sort
    IO.puts "Cleaning directory `#{dstdir}`..."
    File.rm_rf! dstdir
    File.mkdir_p! dstdir

    metalist = mkmeta(dir, proj, files, [])
    tasks_post = Enum.map metalist, fn meta ->
      Task.async fn ->
        [y, m, d] = meta.raw_date
        dow = elem @dowstr, :calendar.day_of_the_week(y, m, d)
        datestr = "#{dow}, #{meta.date}"

        [_, _|lines] = File.read!("#{srcdir}#{meta.file}.md") |> String.split("\n")
        stub = lines |> Earmark.to_html
        html = render(template_post, proj ++ [title: meta.title, date: datestr, tags: meta.tags, contents: stub])
               |> genpage(proj ++ [page_title: meta.title])

        File.open! "#{dstdir}#{meta.file}.html", [:write, :utf8], &(IO.write &1, html)
        IO.puts "  GEN  #{srcdir}#{meta.file}.md -> #{dstdir}#{meta.file}.html"
      end
    end

    IO.puts "Generating posts index..."
    File.open! "#{dstdir}index.html", [:write, :utf8], fn device ->
      html = render(template_list, proj ++ [header: "All Posts", posts: Enum.reverse metalist])
             |> genpage(proj ++ [page_title: "All Posts"])
      IO.write device, html
    end

    File.rm_rf! "#{dir}site/tags/"
    tagmap = Enum.reduce metalist, %{}, fn m, a ->
      tmp = Enum.reduce m.tags, %{}, &(Map.put &2, &1, (Map.get &2, &1, []) ++ [m])
      Map.merge a, tmp, fn _, u, v -> MapSet.to_list(MapSet.new u ++ v) end
    end
    tasks_tag = Enum.map tagmap, fn {k, v} ->
      Task.async fn ->
        tagdir = "#{dir}site/tags/#{k.name}/"
        pt = "Posts Tagged \"#{k.name}\""
        File.mkdir_p! tagdir
        File.open! "#{tagdir}index.html", [:write, :utf8], fn device ->
          html = render(template_list, proj ++ [header: pt, posts: Enum.reverse(v)])
                 |> genpage(proj ++ [page_title: pt])
          IO.write device, html
        end
      end
    end

    Enum.each tasks_post ++ tasks_tag, &(Task.await &1)
  end

  defp process_links(contents, proj) do
    base = Keyword.get proj, :base_url
    contents = Regex.replace @re_media, contents, ~s(\\1="#{base}media/\\2")
    contents = Regex.replace @re_posts, contents, ~s(\\1="#{base}posts/\\2.html")
    contents = Regex.replace @re_pages, contents, ~s(\\1="#{base}\\2.html")
    contents
  end

  defp genpage(contents, ctx) do
    template = Agent.get Global, &(Map.get &1, "template_base")
    contents = process_links contents, ctx
    render template, ctx ++ [contents: contents, navigation: Agent.get(Global, &(Map.get &1, :navstub))]
  end

  defp render(template, assigns) do
    {html, _} = Code.eval_quoted template, [assigns: assigns]
    html
  end

  defp mkmeta(dir, proj, [h|t], l) do
    [year, month, day|_] = String.split(h, "-") |> Enum.map(fn x ->
      case Integer.parse(x) do
        {x, _} -> x
        :error -> nil
      end
    end)
    ["# " <> title, "#" <> tags] =
      File.open!("#{dir}posts/#{h}.md", [:read, :utf8], &([IO.gets(&1, ""), IO.gets(&1, "")]))
    title = title |> String.trim
    tags = tags |> String.split(~r/, ?/)
                |> Enum.filter(&(String.trim(&1) != ""))
                |> Enum.map(fn x ->
                  tag = String.trim x
                  %{name: tag, list_url: "#{Keyword.get proj, :base_url}tags/#{tag}/"}
                end)
    mkmeta(dir, proj, t, l ++ [%Serum.Postmeta{
      file: h,
      title: title,
      date: "#{day} #{elem @monabbr, month} #{year}",
      raw_date: [year, month, day],
      tags: tags,
      url: "#{Keyword.get proj, :base_url}posts/#{h}.html"
    }])
  end

  defp mkmeta(_, _, [], l), do: l
end
