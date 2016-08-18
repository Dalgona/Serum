defmodule Serum do
  require EEx
  import Serum.Payload

  @dowstr {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"}
  @monabbr {"", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
  @re_media ~r/(?<type>href|src)="%25media:(?<url>[^"]*)"/
  @re_posts ~r/(?<type>href|src)="%25posts:(?<url>[^"]*)"/
  @re_pages ~r/(?<type>href|src)="%25pages:(?<url>[^"]*)"/

  def init(dir) do
    dir = if String.ends_with?(dir, "/"), do: dir, else: dir<>"/"
    if File.exists? dir do
      IO.puts "Warning: The directory `#{dir}` already exists and might not be empty."
    end

    ["posts", "pages", "media", "templates", "assets/css", "assets/js", "assets/images"]
    |> Enum.each(fn x ->
      File.mkdir_p! "#{dir}#{x}"
      IO.puts "Created directory `#{dir}#{x}`."
    end)

    projinfo =
      %{site_name: "New Website",
        site_description: "Welcome to my website!",
        author: "Somebody",
        author_email: "somebody@example.com",
        base_url: "/"}
      |> Poison.encode!(pretty: true, indent: 2)
    File.open! "#{dir}serum.json", [:write, :utf8], fn f -> IO.write f, projinfo end
    IO.puts "Generated `#{dir}serum.json`."
    File.open! "#{dir}pages/index.md", [:write, :utf8], fn f -> IO.write f, "*Hello, world!*\n" end
    File.open! "#{dir}pages/pages.json", [:write, :utf8], fn f ->
      tmp = Poison.encode! [
        %Serum.Pageinfo{name: "index", type: "md", title: "Welcome!", menu: true, menu_text: "Home", menu_icon: ""}
      ], pretty: true, indent: 2
      IO.write f, tmp
    end
    IO.puts "Generated `#{dir}pages/pages.json`."

    %{base: template_base,
      nav:  template_nav,
      list: template_list,
      page: template_page,
      post: template_post}
    |> Enum.each(fn {n, t} -> File.open! "#{dir}templates/#{n}.html.eex", [:write, :utf8], &(IO.write &1, t) end)
    IO.puts "Generated essential templates into `#{dir}templates/`."

    File.open! "#{dir}.gitignore", [:write, :utf8], fn f -> IO.write f, "site\n" end
    IO.puts "Generated `#{dir}.gitignore`."

    IO.puts "\nSuccessfully initialized a new Serum project!"
    IO.puts "try `serum build #{dir}` to build the site."
  end

  def build(dir) do
    dir = if String.ends_with?(dir, "/"), do: dir, else: dir<>"/"
    if not File.exists?("#{dir}serum.json") do
      IO.puts "Error: `#{dir}serum.json` not found."
      IO.puts "Make sure you point at a valid Serum project directory."
    else
      IO.puts "Rebuilding Website..."
      :ets.new :build, [:set, :protected, :named_table]

      IO.puts "Reading project infodata `#{dir}serum.json`..."
      proj = File.read!("#{dir}serum.json")
             |> Poison.decode!(keys: :atoms!)
             |> Map.to_list

      IO.puts "Loading templates..."
      ["base", "list", "page", "post", "nav"]
      |> Enum.each(fn x ->
        tree = EEx.compile_file("#{dir}templates/#{x}.html.eex")
        putglobal "template_#{x}", tree
      end)

      File.mkdir_p! "#{dir}site/"
      IO.puts "Created directory `#{dir}site/`."
      pageinfo = File.read!("#{dir}pages/pages.json")
                 |> Poison.decode!(as: [%Serum.Pageinfo{}])
      compile_nav proj, pageinfo
      build_pages dir, proj, pageinfo
      build_posts dir, proj
      copy_assets dir

      IO.puts ""
      IO.puts "Your website is now ready to be served!"
      IO.puts "Copy(move) the contents of `#{dir}site/` directory"
      IO.puts "into your public webpages directory."
      :ets.delete :build
    end
  end

  def compile_nav(proj, info) do
    IO.puts "Compiling main navigation HTML stub..."
    template = getglobal "template_nav"
    html = render template, proj ++ [pages: Enum.filter(info, &(&1.menu))]
    putglobal :navstub, html
  end

  def build_pages(dir, proj, info) do
    template = getglobal "template_page"

    IO.puts "Cleaning pages..."
    File.ls!("#{dir}site/")
    |> Enum.filter(&(String.ends_with? &1, ".html"))
    |> Enum.each(&(File.rm_rf! "#{dir}site/#{&1}"))

    Enum.each info, fn x ->
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
  end

  def build_posts(dir, proj) do
    srcdir = "#{dir}posts/"
    dstdir = "#{dir}site/posts/"
    template_post = getglobal "template_post"
    template_list = getglobal "template_list"

    files = File.ls!(srcdir)
            |> Enum.filter(&(String.ends_with? &1, ".md"))
            |> Enum.map(&(String.replace &1, ~r/\.md$/, ""))
            |> Enum.sort
    IO.puts "Cleaning directory `#{dstdir}`..."
    File.rm_rf! dstdir
    File.mkdir_p! dstdir

    infolist = mkinfo(dir, proj, files, [])
    Enum.each infolist, fn info ->
      [y, m, d] = info.raw_date
      dow = elem @dowstr, :calendar.day_of_the_week(y, m, d)
      datestr = "#{dow}, #{info.date}"

      [_, _|lines] = File.read!("#{srcdir}#{info.file}.md") |> String.split("\n")
      stub = lines |> Earmark.to_html
      html = render(template_post, proj ++ [title: info.title, date: datestr, tags: info.tags, contents: stub])
             |> genpage(proj ++ [page_title: info.title])

      File.open! "#{dstdir}#{info.file}.html", [:write, :utf8], &(IO.write &1, html)
      IO.puts "  GEN  #{srcdir}#{info.file}.md -> #{dstdir}#{info.file}.html"
    end

    IO.puts "Generating posts index..."
    File.open! "#{dstdir}index.html", [:write, :utf8], fn device ->
      html = render(template_list, proj ++ [header: "All Posts", posts: Enum.reverse infolist])
             |> genpage(proj ++ [page_title: "All Posts"])
      IO.write device, html
    end

    File.rm_rf! "#{dir}site/tags/"
    tagmap = Enum.reduce infolist, %{}, fn m, a ->
      tmp = Enum.reduce m.tags, %{}, &(Map.put &2, &1, (Map.get &2, &1, []) ++ [m])
      Map.merge a, tmp, fn _, u, v -> MapSet.to_list(MapSet.new u ++ v) end
    end
    Enum.each tagmap, fn {k, v} ->
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

  def copy_assets(dir) do
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

  defp genpage(contents, ctx) do
    template = getglobal "template_base"
    contents = process_links contents, ctx
    render template, ctx ++ [contents: contents, navigation: getglobal :navstub]
  end

  defp render(template, assigns) do
    {html, _} = Code.eval_quoted template, [assigns: assigns]
    html
  end

  defp process_links(contents, proj) do
    base = Keyword.get proj, :base_url
    contents = Regex.replace @re_media, contents, ~s(\\1="#{base}media/\\2")
    contents = Regex.replace @re_posts, contents, ~s(\\1="#{base}posts/\\2.html")
    contents = Regex.replace @re_pages, contents, ~s(\\1="#{base}\\2.html")
    contents
  end

  defp mkinfo(dir, proj, [h|t], l) do
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
    mkinfo(dir, proj, t, l ++ [%Serum.Postinfo{
      file: h,
      title: title,
      date: "#{day} #{elem @monabbr, month} #{year}",
      raw_date: [year, month, day],
      tags: tags,
      url: "#{Keyword.get proj, :base_url}posts/#{h}.html"
    }])
  end

  defp mkinfo(_, _, [], l), do: l

  defp putglobal(k, v), do: true = :ets.insert :build, {k, v}

  defp getglobal(k) do
    [{_, v}|_] = :ets.lookup :build, k
    v
  end
end
