defmodule Serum.Build do
  @moduledoc """
  This module contains functions for generating pages of your website.
  """

  @dowstr {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"}
  @monabbr {"", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}

  def build(src, dest, mode, display_done \\ false) do
    src = String.ends_with?(src, "/") && src || src <> "/"
    dest = dest || src <> "site/"
    dest = String.ends_with?(dest, "/") && dest || dest <> "/"

    if not File.exists?("#{src}serum.json") do
      IO.puts "[31mError: `#{src}serum.json` not found."
      IO.puts "Make sure you point at a valid Serum project directory.[0m"
    else
      IO.puts "Rebuilding Website..."
      {:ok, pid} = Agent.start_link fn -> %{} end, name: Global

      build_ :load_info, src
      build_ :load_templates, src

      File.mkdir_p! "#{dest}"
      IO.puts "Created directory `#{dest}`."

      {time, _} = :timer.tc(fn ->
        compile_nav
        build_ :launch_tasks, mode, src, dest
      end)
      IO.puts "Build process took #{time}us."
      copy_assets src, dest
      Agent.stop Global

      if display_done do
        IO.puts ""
        IO.puts "[1mYour website is now ready to be served!"
        IO.puts "Copy(move) the contents of `#{dest}` directory"
        IO.puts "into your public webpages directory.[0m\n"
      end
    end
  end

  defp build_(:load_info, dir) do
    IO.puts "Reading project metadata `#{dir}serum.json`..."
    proj = "#{dir}serum.json"
           |> File.read!
           |> Poison.decode!(keys: :atoms)
           |> Map.to_list
    pageinfo = "#{dir}pages/pages.json"
               |> File.read!
               |> Poison.decode!(as: [%Serum.Pageinfo{}])
    Agent.update Global, &(Map.put &1, :proj, proj)
    Agent.update Global, &(Map.put &1, :pageinfo, pageinfo)
  end

  defp build_(:load_templates, dir) do
    IO.puts "Loading templates..."
    ["base", "list", "page", "post", "nav"]
    |> Enum.each(fn x ->
      tree = EEx.compile_file("#{dir}templates/#{x}.html.eex")
      Agent.update Global, &(Map.put &1, "template_#{x}", tree)
    end)
  end

  defp build_(:launch_tasks, :parallel, src, dest) do
    IO.puts "⚡️  [1mStarting parallel build...[0m"
    t1 = Task.async fn -> build_pages src, dest, :parallel end
    t2 = Task.async fn -> build_posts src, dest, :parallel end
    Task.await t1
    Task.await t2
  end

  defp build_(:launch_tasks, :sequential, src, dest) do
    IO.puts "⌛️  [1mStarting sequential build...[0m"
    build_pages src, dest, :sequential
    build_posts src, dest, :sequential
  end

  defp compile_nav do
    proj = Agent.get Global, &(Map.get &1, :proj)
    info = Agent.get Global, &(Map.get &1, :pageinfo)
    IO.puts "Compiling main navigation HTML stub..."
    template = Agent.get Global, &(Map.get &1, "template_nav")
    html = render template, proj ++ [pages: Enum.filter(info, &(&1.menu))]
    Agent.update Global, &(Map.put &1, :navstub, html)
  end

  defp build_pages(src, dest, mode) do
    template = Agent.get Global, &(Map.get &1, "template_page")
    info = Agent.get Global, &(Map.get &1, :pageinfo)

    IO.puts "Cleaning pages..."

    dest
    |> File.ls!
    |> Enum.filter(&(String.ends_with? &1, ".html"))
    |> Enum.each(&(File.rm_rf! "#{dest}#{&1}"))

    case mode do
      :parallel -> (fn ->
        info
        |> Enum.map(&(Task.async Serum.Build, :page_task, [src, dest, &1, template]))
        |> Enum.each(&(Task.await &1))
      end).()
      _ -> (fn ->
        info
        |> Enum.each(&(page_task src, dest, &1, template))
      end).()
    end
  end

  def page_task(src, dest, info, template) do
    txt = File.read!("#{src}pages/#{info.name}.#{info.type}")
    html = case info.type do
      "md" -> Earmark.to_html txt
      "html" -> txt
    end
    html = template
           |> render([contents: html])
           |> genpage([page_title: info.title])
    File.open! "#{dest}#{info.name}.html", [:write, :utf8], fn device ->
      IO.write device, html
    end
    IO.puts "  GEN  #{src}pages/#{info.name}.#{info.type} -> #{dest}#{info.name}.html"
  end

  defp build_posts(src, dest, mode) do
    srcdir = "#{src}posts/"
    dstdir = "#{dest}posts/"
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

    infolist = mkinfo(src, files, [])
    tasks_post = launch_post mode, infolist, srcdir, dstdir, template_post

    IO.puts "Generating posts index..."
    File.open! "#{dstdir}index.html", [:write, :utf8], fn device ->
      html = template_list
             |> render(proj ++ [header: "All Posts", posts: Enum.reverse infolist])
             |> genpage(proj ++ [page_title: "All Posts"])
      IO.write device, html
    end

    File.rm_rf! "#{dest}tags/"
    tagmap = Enum.reduce infolist, %{}, fn m, a ->
      tmp = Enum.reduce m.tags, %{}, &(Map.put &2, &1, (Map.get &2, &1, []) ++ [m])
      Map.merge a, tmp, fn _, u, v -> MapSet.to_list(MapSet.new u ++ v) end
    end
    tasks_tag = launch_tag mode, tagmap, dest, template_list

    Enum.each tasks_post ++ tasks_tag, &(Task.await &1)
  end

  defp launch_post(:parallel, info, srcdir, dstdir, template) do
    info
    |> Enum.map(&(Task.async Serum.Build, :post_task, [srcdir, dstdir, &1, template]))
  end

  defp launch_post(:sequential, info, srcdir, dstdir, template) do
    info
    |> Enum.each(&(post_task srcdir, dstdir, &1, template))
    []
  end

  defp launch_tag(:parallel, tagmap, dir, template) do
    tagmap
    |> Enum.map(&(Task.async Serum.Build, :tag_task, [dir, &1, template]))
  end

  defp launch_tag(:sequential, tagmap, dir, template) do
    tagmap
    |> Enum.each(&(tag_task dir, &1, template))
    []
  end

  def post_task(srcdir, dstdir, info, template) do
    [y, m, d] = info.raw_date
    dow = elem @dowstr, :calendar.day_of_the_week(y, m, d)
    datestr = "#{dow}, #{info.date}"

    [_, _|lines] = "#{srcdir}#{info.file}.md" |> File.read! |> String.split("\n")
    stub = lines |> Earmark.to_html
    html = template
           |> render([title: info.title, date: datestr, tags: info.tags, contents: stub])
           |> genpage([page_title: info.title])

    File.open! "#{dstdir}#{info.file}.html", [:write, :utf8], &(IO.write &1, html)
    IO.puts "  GEN  #{srcdir}#{info.file}.md -> #{dstdir}#{info.file}.html"
  end

  def tag_task(dest, {k, v}, template) do
    tagdir = "#{dest}tags/#{k.name}/"
    pt = "Posts Tagged \"#{k.name}\""
    posts = v |> Enum.sort(&(&1.file > &2.file))
    File.mkdir_p! tagdir
    File.open! "#{tagdir}index.html", [:write, :utf8], fn device ->
      html = template
             |> render([header: pt, posts: posts])
             |> genpage([page_title: pt])
      IO.write device, html
    end
    IO.puts "  GEN  #{tagdir}index.html"
  end

  defp process_links(text, proj) do
    base = Keyword.get proj, :base_url
    text = Regex.replace ~r/(?<type>href|src)="%25media:(?<url>[^"]*)"/, text, ~s(\\1="#{base}media/\\2")
    text = Regex.replace ~r/(?<type>href|src)="%25posts:(?<url>[^"]*)"/, text, ~s(\\1="#{base}posts/\\2.html")
    text = Regex.replace ~r/(?<type>href|src)="%25pages:(?<url>[^"]*)"/, text, ~s(\\1="#{base}\\2.html")
    text
  end

  defp genpage(contents, ctx) do
    proj = Agent.get Global, &(Map.get &1, :proj)
    base = Agent.get Global, &(Map.get &1, "template_base")
    contents = process_links contents, proj
    render base, proj ++ ctx ++ [contents: contents, navigation: Agent.get(Global, &(Map.get &1, :navstub))]
  end

  defp render(template, assigns) do
    proj = Agent.get Global, &(Map.get &1, :proj)
    {html, _} = Code.eval_quoted template, [assigns: proj ++ assigns]
    html
  end

  defp mkinfo(dir, [h|t], l) do
    proj = Agent.get Global, &(Map.get &1, :proj)
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
      mkinfo(dir, t, l ++ [%Serum.Postinfo{
        file: h,
        title: title,
        date: "#{day} #{elem @monabbr, month} #{year}",
        raw_date: [year, month, day],
        tags: tags,
        url: "#{Keyword.get proj, :base_url}posts/#{h}.html"
      }])
    rescue
      _ in MatchError -> (fn ->
        IO.puts "[31mError while parsing `#{dir}posts/#{h}.md`: invalid markdown format[0m"
        exit "error while building blog posts"
      end).()
    end
  end

  defp mkinfo(_, [], l), do: l

  defp copy_assets(src, dest) do
    IO.puts "Cleaning assets and media directories..."
    File.rm_rf! "#{dest}assets/"
    File.rm_rf! "#{dest}media/"
    IO.puts "Copying assets and media..."
    case File.cp_r("#{src}assets/", "#{dest}assets/") do
      {:error, :enoent, _} -> IO.puts "[93mAssets directory not found. Skipping...[0m"
      {:ok, _} -> :ok
    end
    case File.cp_r("#{src}media/", "#{dest}media/") do
      {:error, :enoent, _} -> IO.puts "[93mMedia directory not found. Skipping...[0m"
      {:ok, _} -> :ok
    end
  end
end
