defmodule Serum do
  require EEx

  @dowstr {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"}
  @monabbr {"", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}

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

    projmeta =
      %{site_name: "New Website",
        site_description: "Welcome to my website!",
        author: "Somebody",
        author_email: "somebody@example.com",
        base_url: "/"}
      |> Poison.encode!(pretty: true, indent: 2)
    File.open! "#{dir}serum.json", [:write], fn f -> IO.write f, projmeta end
    IO.puts "Generated `#{dir}serum.json`."
    File.open! "#{dir}pages/pages.json", [:write], fn f -> IO.write f, "[]" end
    IO.puts "Generated `#{dir}pages/pages.json`."
    File.open! "#{dir}posts/README", [:write], fn f -> IO.write f, Serum.Payload.posts_readme end
    IO.puts "Generated `#{dir}posts/README`."

    File.open! "#{dir}templates/base.html.eex", [:write], fn f -> IO.write f, Serum.Payload.template_base end
    File.open! "#{dir}templates/nav.html.eex", [:write], fn f -> IO.write f, Serum.Payload.template_nav end
    File.open! "#{dir}templates/list.html.eex", [:write], fn f -> IO.write f, Serum.Payload.template_list end
    File.open! "#{dir}templates/post.html.eex", [:write], fn f -> IO.write f, Serum.Payload.template_post end
    IO.puts "Generated essential templates into `#{dir}templates/`."

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

      IO.puts "Reading project metadata `#{dir}serum.json`..."
      proj = File.read!("#{dir}serum.json")
             |> Poison.decode!(keys: :atoms!)
             |> Map.to_list

      IO.puts "Loading templates..."
      ["base", "list", "post", "nav"]
      |> Enum.each(fn x ->
        tree = EEx.compile_file("#{dir}templates/#{x}.html.eex")
        putglobal "template_#{x}", tree
      end)

      File.mkdir_p! "#{dir}site/"
      IO.puts "Created directory `#{dir}site/`."
      pagemeta = File.read!("#{dir}pages/pages.json")
                 |> Poison.decode!(as: [%Serum.Pagemeta{}])
      compile_nav proj, pagemeta
      build_pages dir, proj, pagemeta
      build_posts dir, proj
      copy_assets dir

      IO.puts ""
      IO.puts "Your website is now ready to be served!"
      IO.puts "Copy(move) the contents of `#{dir}site/` directory"
      IO.puts "into your public webpages directory."
      :ets.delete :build
    end
  end

  def compile_nav(proj, meta) do
    IO.puts "Compiling main navigation HTML stub..."
    template = getglobal "template_nav"
    html = render template, proj ++ [pages: Enum.filter(meta, &(&1.menu))]
    putglobal :navstub, html
  end

  def build_pages(dir, proj, meta) do
    IO.puts "Cleaning pages..."
    File.ls!("#{dir}site/")
    |> Enum.filter(&(String.ends_with? &1, ".html"))
    |> Enum.each(&(File.rm_rf! &1))
    Enum.each meta, fn x ->
      txt = File.read!("#{dir}pages/#{x.name}.#{x.type}")
      html = case x.type do
        "md" -> Earmark.to_html txt
        "html" -> txt
      end
      html = genpage(html, proj ++ [page_title: x.title])
      File.open! "#{dir}site/#{x.name}.html", [:write], fn device ->
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

    Enum.each files, fn x ->
      [year, month, day|_] = String.split(x, "-") |> Enum.map(fn x ->
        case Integer.parse(x) do
          {int, _} -> int
          :error -> nil
        end
      end)
      dow = elem @dowstr, :calendar.day_of_the_week(year, month, day)
      datestr = "#{dow}, #{day} #{elem @monabbr, month} #{year}"

      [title|lines] = File.read!("#{srcdir}#{x}.md") |> String.split("\n")
      title = title |> String.trim |> String.replace(~r/^# /, "")
      stub = lines |> Earmark.to_html
      html = render(template_post, proj ++ [title: title, date: datestr, contents: stub])
             |> genpage(proj ++ [page_title: title])
      File.open!("#{dstdir}#{x}.html", [:write], fn device ->
        IO.write device, html
      end)
      IO.puts "  GEN  #{srcdir}#{x}.md -> #{dstdir}#{x}.html"
    end

    IO.puts "Generating posts index..."
    metalist = mkmeta(dir, proj, files, [])
    File.open!("#{dstdir}index.html", [:write], fn device ->
      html = render(template_list, proj ++ [posts: Enum.reverse metalist])
             |> genpage(proj ++ [page_title: "All Posts"])
      IO.write device, html
    end)
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
    render template, ctx ++ [contents: contents, navigation: getglobal :navstub]
  end

  defp render(template, assigns) do
    {html, _} = Code.eval_quoted template, [assigns: assigns]
    html
  end

  defp mkmeta(dir, proj, [h|t], l) do
    url = "#{Keyword.get proj, :base_url}posts/#{h}.html"
    [year, month, day|_] = String.split(h, "-") |> Enum.map(fn x ->
      case Integer.parse(x) do
        {x, _} -> x
        :error -> nil
      end
    end)
    title = File.open!("#{dir}posts/#{h}.md", [:read], fn device -> IO.gets device, "" end)
            |> String.trim
            |> String.replace(~r/^# /, "")
    mkmeta(dir, proj, t, l ++ [%Serum.Postmeta{
      title: title,
      date: "#{day} #{elem @monabbr, month} #{year}",
      file: url
    }])
  end

  defp mkmeta(_, _, [], l), do: l

  defp putglobal(k, v), do: true = :ets.insert :build, {k, v}

  defp getglobal(k) do
    [{_, v}|_] = :ets.lookup :build, k
    v
  end
end
