defmodule Serum.Build do
  @moduledoc """
  This module contains functions for generating pages of your website.
  """

  @dowstr {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"}
  @monabbr {"", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}

  def build(dir, mode) do
    dir = if String.ends_with?(dir, "/"), do: dir, else: dir <> "/"
    if not File.exists?("#{dir}serum.json") do
      IO.puts "Error: `#{dir}serum.json` not found."
      IO.puts "Make sure you point at a valid Serum project directory."
    else
      IO.puts "Rebuilding Website..."
      {:ok, pid} = Agent.start_link fn -> %{} end, name: Global

      IO.puts "Reading project infodata `#{dir}serum.json`..."
      proj = "#{dir}serum.json"
             |> File.read!
             |> Poison.decode!(keys: :atoms)
             |> Map.to_list
      Agent.update Global, &(Map.put &1, :proj, proj)

      IO.puts "Loading templates..."
      ["base", "list", "page", "post", "nav"]
      |> Enum.each(fn x ->
        tree = EEx.compile_file("#{dir}templates/#{x}.html.eex")
        Agent.update Global, &(Map.put &1, "template_#{x}", tree)
      end)

      File.mkdir_p! "#{dir}site/"
      IO.puts "Created directory `#{dir}site/`."
      pageinfo = "#{dir}pages/pages.json"
                 |> File.read!
                 |> Poison.decode!(as: [%Serum.Pageinfo{}])
      {time, _} = :timer.tc(fn ->
        compile_nav pageinfo
        case mode do
          :parallel -> (fn ->
            IO.puts "⚡️  [97mStarting parallel build...[0m"
            t1 = Task.async fn -> build_pages dir, pageinfo, mode end
            t2 = Task.async fn -> build_posts dir, mode end
            Task.await t1
            Task.await t2
          end).()
          _ -> (fn ->
            IO.puts "⌛️  [97mStarting sequential build...[0m"
            build_pages dir, pageinfo, mode
            build_posts dir, mode
          end).()
        end
      end)
      IO.puts "Build process took #{time}us."
      copy_assets dir

      IO.puts ""
      IO.puts "[97mYour website is now ready to be served!"
      IO.puts "Copy(move) the contents of `#{dir}site/` directory"
      IO.puts "into your public webpages directory.[0m\n"
    end
  end

  defp compile_nav(info) do
    proj = Agent.get Global, &(Map.get &1, :proj)
    IO.puts "Compiling main navigation HTML stub..."
    template = Agent.get Global, &(Map.get &1, "template_nav")
    html = render template, proj ++ [pages: Enum.filter(info, &(&1.menu))]
    Agent.update Global, &(Map.put &1, :navstub, html)
  end

  defp build_pages(dir, info, mode) do
    template = Agent.get Global, &(Map.get &1, "template_page")

    IO.puts "Cleaning pages..."

    "#{dir}site/"
    |> File.ls!
    |> Enum.filter(&(String.ends_with? &1, ".html"))
    |> Enum.each(&(File.rm_rf! "#{dir}site/#{&1}"))

    case mode do
      :parallel -> (fn ->
        info
        |> Enum.map(&(Task.async Serum.Build, :page_task, [dir, &1, template]))
        |> Enum.each(&(Task.await &1))
      end).()
      _ -> (fn ->
        info
        |> Enum.each(&(page_task dir, &1, template))
      end).()
    end
  end

  def page_task(dir, info, template) do
    txt = File.read!("#{dir}pages/#{info.name}.#{info.type}")
    html = case info.type do
      "md" -> Earmark.to_html txt
      "html" -> txt
    end
    html = template
           |> render([contents: html])
           |> genpage([page_title: info.title])
    File.open! "#{dir}site/#{info.name}.html", [:write, :utf8], fn device ->
      IO.write device, html
    end
    IO.puts "  GEN  #{dir}pages/#{info.name}.#{info.type} -> #{dir}site/#{info.name}.html"
  end

  defp build_posts(dir, mode) do
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

    infolist = mkinfo(dir, files, [])
    tasks_post =
      case mode do
        :parallel ->
          infolist
          |> Enum.map(&(Task.async Serum.Build, :post_task, [srcdir, dstdir, &1, template_post]))
        _ -> (fn ->
          infolist
          |> Enum.each(&(post_task srcdir, dstdir, &1, template_post))
          []
        end).()
      end

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
    tasks_tag =
      case mode do
        :parallel ->
          tagmap
          |> Enum.map(&(Task.async Serum.Build, :tag_task, [dir, &1, template_list]))
        _ -> (fn ->
          tagmap
          |> Enum.each(&(tag_task dir, &1, template_list))
          []
        end).()
      end

    Enum.each tasks_post ++ tasks_tag, &(Task.await &1)
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

  def tag_task(dir, {k, v}, template) do
    tagdir = "#{dir}site/tags/#{k.name}/"
    pt = "Posts Tagged \"#{k.name}\""
    posts = v |> Enum.sort(&(&1.file > &2.file))
    File.mkdir_p! tagdir
    File.open! "#{tagdir}index.html", [:write, :utf8], fn device ->
      html = template
             |> render([header: pt, posts: posts])
             |> genpage([page_title: pt])
      IO.write device, html
    end
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
        IO.puts "\e[31mError while parsing `#{dir}posts/#{h}.md`: invalid markdown format\e[0m"
        exit "error while building blog posts"
      end).()
    end
  end

  defp mkinfo(_, [], l), do: l

  defp copy_assets(dir) do
    IO.puts "Cleaning assets and media directories..."
    File.rm_rf! "#{dir}site/assets/"
    File.rm_rf! "#{dir}site/media/"
    IO.puts "Copying assets and media..."
    case File.cp_r("#{dir}assets/", "#{dir}site/assets/") do
      {:error, :enoent, _} -> IO.puts "Assets directory not found. Skipping..."
      {:ok, _} -> nil
    end
    case File.cp_r("#{dir}media/", "#{dir}site/media/") do
      {:error, :enoent, _} -> IO.puts "Media directory not found. Skipping..."
      {:ok, _} -> nil
    end
  end
end
