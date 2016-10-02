defmodule Serum.Build do
  @moduledoc """
  This module contains functions for generating pages of your website.
  """

  @default_date_format    "{YYYY}-{0M}-{0D}"
  @default_preview_length 200

  def build(src, dest, mode, display_done \\ false) do
    src = String.ends_with?(src, "/") && src || src <> "/"
    dest = dest || src <> "site/"
    dest = String.ends_with?(dest, "/") && dest || dest <> "/"

    if not File.exists?("#{src}serum.json") do
      IO.puts "\x1b[31mError: `#{src}serum.json` not found."
      IO.puts "Make sure you point at a valid Serum project directory.\x1b[0m"
      {:error, :no_project}
    else
      IO.puts "Rebuilding Website..."
      {:ok, _pid} = Agent.start_link fn -> %{} end, name: Global

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
        IO.puts "\x1b[1mYour website is now ready to be served!"
        IO.puts "Copy(move) the contents of `#{dest}` directory"
        IO.puts "into your public webpages directory.\x1b[0m\n"
      end

      {:ok, dest}
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
    IO.puts "⚡️  \x1b[1mStarting parallel build...\x1b[0m"
    t1 = Task.async fn -> build_pages src, dest, :parallel end
    t2 = Task.async fn -> build_posts src, dest, :parallel end
    Task.await t1
    Task.await t2
  end

  defp build_(:launch_tasks, :sequential, src, dest) do
    IO.puts "⌛️  \x1b[1mStarting sequential build...\x1b[0m"
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
      :parallel ->
        info
        |> Enum.map(&(Task.async Serum.Build, :page_task, [src, dest, &1, template]))
        |> Enum.each(&(Task.await &1))
      _ ->
        info
        |> Enum.each(&(page_task src, dest, &1, template))
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
    {:ok, _pid} = Agent.start_link fn -> [] end, name: Serum.Build.PostInfoStorage

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

    Enum.each launch_post(mode, files, srcdir, dstdir, template_post), &Task.await&1
    infolist = Serum.Build.PostInfoStorage
           |> Agent.get(&(&1))
           |> Enum.sort_by(&(&1.file))

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
    Enum.each launch_tag(mode, tagmap, dest, template_list), &Task.await&1

    Agent.stop Serum.Build.PostInfoStorage
  end

  defp launch_post(:parallel, files, srcdir, dstdir, template) do
    files
    |> Enum.map(&(Task.async Serum.Build, :post_task, [srcdir, dstdir, &1, template]))
  end

  defp launch_post(:sequential, files, srcdir, dstdir, template) do
    files
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

  def post_task(srcdir, dstdir, file, template) do
    proj = Agent.get Global, &(Map.get &1, :proj)

    [l1, l2|lines] = "#{srcdir}#{file}.md" |> File.read! |> String.split("\n")
    stub = lines |> Earmark.to_html
    plen = Keyword.get(proj, :preview_length) || @default_preview_length
    preview = make_preview stub, plen
    {year, month, day, hour, minute} = extract_date srcdir, file
    {title, tags} = extract_title_tags srcdir, file, l1, l2, proj
    datetime = {{year, month, day}, {hour, minute, 0}}
               |> Timex.to_datetime(:local)
               |> Timex.format!(Keyword.get(proj, :date_format) || @default_date_format)
    html = template
           |> render([title: title, date: datetime, tags: tags, contents: stub])
           |> genpage([page_title: title])

    File.open! "#{dstdir}#{file}.html", [:write, :utf8], &(IO.write &1, html)
    IO.puts "  GEN  #{srcdir}#{file}.md -> #{dstdir}#{file}.html"

    info = %Serum.Postinfo{
      file: file,
      title: title,
      date: datetime,
      raw_date: [year, month, day, hour, minute],
      tags: tags,
      url: "#{Keyword.get proj, :base_url}posts/#{file}.html",
      preview_text: preview
    }
    Agent.update Serum.Build.PostInfoStorage, &([info|&1])
  end

  defp make_preview(_html, 0) do
    ""
  end

  defp make_preview(html, maxlen) do
    html
    |> Floki.parse
    |> Enum.filter(&(elem(&1, 0) == "p"))
    |> Enum.map(&(Floki.text elem(&1, 2)))
    |> Enum.join(" ")
    |> String.slice(0, maxlen)
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

  defp mkinfo_fail(srcdir, file, reason) do
    IO.puts "\x1b[31mError while parsing `#{srcdir}#{file}.md`: #{reason}\x1b[0m"
    exit "error while building blog posts"
  end

  defp extract_date(srcdir, filename) do
    try do
      [y, m, d, hhmm|_] = filename |> String.split("-") |> Enum.map(fn x ->
        case Integer.parse(x) do
          {x, _} -> x
          :error -> :nil
        end
      end)
      if Enum.find_index([y, m, d, hhmm], &(&1 == nil)) != nil do
        raise MatchError
      end
      {h, i} =
        with h <- div(hhmm, 100), i <- rem(hhmm, 100) do
          h = if h > 23, do: 23, else: h
          i = if i > 59, do: 59, else: i
          {h, i}
        end
      {y, m, d, h, i}
    rescue
      _ in MatchError ->
        mkinfo_fail srcdir, filename, :invalid_filename
    end
  end

  defp extract_title_tags(srcdir, filename, title, tags, proj) do
    try do
      {"# " <> title, "#" <> tags} = {title, tags}
      title = title |> String.trim
      tags = tags |> String.split(~r/, ?/)
                  |> Enum.filter(&(String.trim(&1) != ""))
                  |> Enum.map(fn x ->
                    tag = String.trim x
                    %{name: tag, list_url: "#{Keyword.get proj, :base_url}tags/#{tag}/"}
                  end)
      {title, tags}
    rescue
      _ in MatchError ->
        mkinfo_fail srcdir, filename, :invalid_header
    end
  end

  defp copy_assets(src, dest) do
    IO.puts "Cleaning assets and media directories..."
    File.rm_rf! "#{dest}assets/"
    File.rm_rf! "#{dest}media/"
    IO.puts "Copying assets and media..."
    case File.cp_r("#{src}assets/", "#{dest}assets/") do
      {:error, :enoent, _} -> IO.puts "\x1b[93mAssets directory not found. Skipping...\x1b[0m"
      {:ok, _} -> :ok
    end
    case File.cp_r("#{src}media/", "#{dest}media/") do
      {:error, :enoent, _} -> IO.puts "\x1b[93mMedia directory not found. Skipping...\x1b[0m"
      {:ok, _} -> :ok
    end
  end
end
