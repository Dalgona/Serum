defmodule Serum.Build do
  @dowstr {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"}
  @monabbr {"", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
  @re_media ~r/(?<type>href|src)="%25media:(?<url>[^"]*)"/
  @re_posts ~r/(?<type>href|src)="%25posts:(?<url>[^"]*)"/
  @re_pages ~r/(?<type>href|src)="%25pages:(?<url>[^"]*)"/

  def compile_nav(info) do
    proj = Agent.get Global, &(Map.get &1, :proj)
    IO.puts "Compiling main navigation HTML stub..."
    template = Agent.get Global, &(Map.get &1, "template_nav")
    html = render template, proj ++ [pages: Enum.filter(info, &(&1.menu))]
    Agent.update Global, &(Map.put &1, :navstub, html)
  end

  def build_pages(dir, info) do
    template = Agent.get Global, &(Map.get &1, "template_page")
    proj = Agent.get Global, &(Map.get &1, :proj)

    IO.puts "Cleaning pages..."
    "#{dir}site/"
    |> File.ls!
    |> Enum.filter(&(String.ends_with? &1, ".html"))
    |> Enum.each(&(File.rm_rf! "#{dir}site/#{&1}"))

    info
    |> Enum.map(&(Task.async Serum.Build, :page_task, [dir, proj, &1, template]))
    |> Enum.each(&(Task.await &1))
  end

  def page_task(dir, proj, info, template) do
    txt = File.read!("#{dir}pages/#{info.name}.#{info.type}")
    html = case info.type do
      "md" -> Earmark.to_html txt
      "html" -> txt
    end
    html = template
           |> render(proj ++ [contents: html])
           |> genpage(proj ++ [page_title: info.title])
    File.open! "#{dir}site/#{info.name}.html", [:write, :utf8], fn device ->
      IO.write device, html
    end
    IO.puts "  GEN  #{dir}pages/#{info.name}.#{info.type} -> #{dir}site/#{info.name}.html"
  end

  def build_posts(dir) do
    srcdir = "#{dir}posts/"
    dstdir = "#{dir}site/posts/"
    template_post = Agent.get Global, &(Map.get &1, "template_post")
    template_list = Agent.get Global, &(Map.get &1, "template_list")
    proj = Agent.get Global, &(Map.get &1, :proj)

    files = srcdir
            |> File.ls!
            |> Enum.filter(&(String.ends_with? &1, ".md"))
            |> Enum.map(&(String.replace &1, ~r/\.md$/, ""))
            |> Enum.sort
    IO.puts "Cleaning directory `#{dstdir}`..."
    File.rm_rf! dstdir
    File.mkdir_p! dstdir

    infolist = mkinfo(dir, proj, files, [])
    tasks_post = Enum.map infolist, &(Task.async Serum.Build, :post_task, [srcdir, dstdir, proj, &1, template_post])

    IO.puts "Generating posts index..."
    File.open! "#{dstdir}index.html", [:write, :utf8], fn device ->
      html = template_list
             |> render(proj ++ [header: "All Posts", posts: Enum.reverse infolist])
             |> genpage(proj ++ [page_title: "All Posts"])
      IO.write device, html
    end

    File.rm_rf! "#{dir}site/tags/"
    tagmap = Enum.reduce infolist, %{}, fn m, a ->
      tmp = Enum.reduce m.tags, %{}, &(Map.put &2, &1, (Map.get &2, &1, []) ++ [m])
      Map.merge a, tmp, fn _, u, v -> MapSet.to_list(MapSet.new u ++ v) end
    end
    tasks_tag = Enum.map tagmap, &(Task.async Serum.Build, :tag_task, [dir, proj, &1, template_list])

    Enum.each tasks_post ++ tasks_tag, &(Task.await &1)
  end

  def post_task(srcdir, dstdir, proj, info, template) do
    [y, m, d] = info.raw_date
    dow = elem @dowstr, :calendar.day_of_the_week(y, m, d)
    datestr = "#{dow}, #{info.date}"

    [_, _|lines] = "#{srcdir}#{info.file}.md" |> File.read!  |> String.split("\n")
    stub = lines |> Earmark.to_html
    html = template
           |> render(proj ++ [title: info.title, date: datestr, tags: info.tags, contents: stub])
           |> genpage(proj ++ [page_title: info.title])

    File.open! "#{dstdir}#{info.file}.html", [:write, :utf8], &(IO.write &1, html)
    IO.puts "  GEN  #{srcdir}#{info.file}.md -> #{dstdir}#{info.file}.html"
  end

  def tag_task(dir, proj, {k, v}, template) do
    tagdir = "#{dir}site/tags/#{k.name}/"
    pt = "Posts Tagged \"#{k.name}\""
    File.mkdir_p! tagdir
    File.open! "#{tagdir}index.html", [:write, :utf8], fn device ->
      html = template
             |> render(proj ++ [header: pt, posts: Enum.reverse(v)])
             |> genpage(proj ++ [page_title: pt])
      IO.write device, html
    end
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

  defp mkinfo(dir, proj, [h|t], l) do
    [year, month, day|_] = h |> String.split("-") |> Enum.map(fn x ->
      case Integer.parse(x) do
        {x, _} -> x
        :error -> nil
      end
    end)
    try do
      ["# " <> title, "#" <> tags] =
        File.open!("#{dir}posts/#{h}.md", [:read, :utf8], &([IO.gets(&1, ""), IO.gets(&1, "")]))
      title = title |> String.trim
      tags = tags |> String.split(~r/, ?/)
                  |> Enum.filter(&(String.trim(&1) != ""))
                  |> Enum.map(fn x ->
                    tag = String.trim x
                    %{name: tag, list_url: "#{Keyword.get proj, :base_url}tags/#{tag}/"}
                  end)
      mkinfo(dir, proj, t, l ++ [%Serum.Postinfo{
        file: h,
        title: title,
        date: "#{day} #{elem @monabbr, month} #{year}",
        raw_date: [year, month, day],
        tags: tags,
        url: "#{Keyword.get proj, :base_url}posts/#{h}.html"
      }])
    rescue
      _ in MatchError -> (fn ->
        IO.puts "\e[31mError while parsing `#{dir}posts/#{h}.md`: invalid markdown format\e[0m"
        exit "error while building blog posts"
      end).()
    end
  end

  defp mkinfo(_, _, [], l), do: l
end
