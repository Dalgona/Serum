defmodule Serum do
  require EEx

  @templates "templates/"
  @src_posts "posts/"
  @src_pages "pages/"
  @src_assets "assets/"
  @src_media "media/"
  @posts "site/posts/"
  @pages "site/"
  @assets "site/assets/"
  @media "site/media/"

  EEx.function_from_file :defp, :navhtml, @templates <> "nav.html.eex", [:assigns]
  EEx.function_from_file :defp, :listhtml, @templates <> "list.html.eex", [:assigns]
  EEx.function_from_file :defp, :posthtml, @templates <> "post.html.eex", [:contents, :assigns]
  EEx.function_from_file :defp, :basehtml, @templates <> "base.html.eex", [:contents, :assigns]

  def init(), do: init "."

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

    File.open! "#{dir}templates/base.html.eex", [:write], fn f -> IO.write f, Serum.Payload.template_base end
    File.open! "#{dir}templates/nav.html.eex", [:write], fn f -> IO.write f, Serum.Payload.template_nav end
    File.open! "#{dir}templates/list.html.eex", [:write], fn f -> IO.write f, Serum.Payload.template_list end
    File.open! "#{dir}templates/post.html.eex", [:write], fn f -> IO.write f, Serum.Payload.template_post end
    IO.puts "Generated essential templates into `#{dir}templates/`."

    IO.puts "\nSuccessfully initialized a new Serum project!"
    IO.puts "try `serum build #{dir}` to build the site."
  end

  def build() do
    IO.puts "Rebuilding Website..."
    context = Application.get_all_env :serum
    pagemeta = File.read!("#{@src_pages}pages.json")
               |> Poison.decode!(as: [%Serum.Pagemeta{}])
    compile_nav pagemeta, context
    build_posts context
    build_pages pagemeta, context
    copy_assets
    IO.puts ""
    IO.puts "Your website is now ready to be served!"
    IO.puts "Copy(move) the contents of `#{@pages}` directory"
    IO.puts "into your public webpages directory."
  end

  def compile_nav(meta, ctx) do
    IO.puts "Compiling main navigation HTML stub..."
    html = navhtml(ctx ++ [pages: Enum.filter(meta, &(&1.menu))])
    Application.put_env :serum, :navstub, html
  end

  def build_posts(ctx) do
    files = File.ls!(@src_posts)
            |> Enum.filter(&(String.ends_with? &1, ".md"))
            |> Enum.map(&(String.replace &1, ~r/\.md$/, ""))
            |> Enum.sort
    IO.puts "Cleaning directory `#{@posts}`..."
    File.rm_rf! @posts
    File.mkdir_p! @posts

    metalist = mkmeta(files, [])

    Enum.each files, fn x ->
      [year, month, day|_] = String.split(x, "-") |> Enum.map(fn x ->
        case Integer.parse(x) do
          {int, _} -> int
          :error -> nil
        end
      end)
      dow = dowstr :calendar.day_of_the_week(year, month, day)
      datestr = "#{dow}, #{day} #{monabbr month} #{year}"

      [title|lines] = File.read!("#{@src_posts}#{x}.md") |> String.split("\n")
      title = title |> String.trim |> String.replace(~r/^# /, "")
      try do
        {:ok, stub} = lines |> Enum.join("\n") |> Pandex.commonmark_to_html5
        html = stub
               |> posthtml(ctx ++ [title: title, date: datestr])
               |> genpage(ctx ++ [page_title: title])
        File.open!("#{@posts}#{x}.html", [:write], fn device ->
          IO.write device, html
        end)
      rescue
        _ in ErlangError -> exit "`pandoc` (>= 1.14) is required for the build process."
      end
      IO.puts "  GEN  #{@src_posts}#{x}.md -> #{@posts}#{x}.html"
    end

    IO.puts "Generating posts index..."
    File.open!("#{@posts}index.html", [:write], fn device ->
      IO.write device, (listhtml(ctx ++ [posts: Enum.reverse(metalist)]) |> genpage(ctx ++ [page_title: "All Posts"]))
    end)
  end

  def build_pages(meta, ctx) do
    IO.puts "Cleaning pages..."
    File.ls!(@pages)
    |> Enum.filter(&(String.ends_with? &1, ".html"))
    |> Enum.each(&(File.rm_rf! &1))
    Enum.each meta, fn x ->
      txt = File.read!("#{@src_pages}#{x.name}.#{x.type}")
      try do
        {_, html} = case x.type do
          "md" -> Pandex.commonmark_to_html5 txt
          "html" -> {nil, txt}
        end
        html = genpage(html, ctx ++ [page_title: x.title])
        File.open! "#{@pages}#{x.name}.html", [:write], fn device ->
          IO.write device, html
        end
      rescue
        _ in ErlangError -> exit "`pandoc` (>= 1.14) is required for the build process."
      end
      IO.puts "  GEN  #{@src_pages}#{x.name}.#{x.type} -> #{@pages}#{x.name}.html"
    end
  end

  def copy_assets() do
    IO.puts "Cleaning assets and media directories..."
    File.rm_rf! @assets
    File.rm_rf! @media
    IO.puts "Copying assets and media..."
    case File.cp_r(@src_assets, @assets) do
      {:error, :enoent, _} -> IO.puts "Assets directory not found. Skipping..."
      {:ok, _} -> nil
    end
    case File.cp_r(@src_media, @media) do
      {:error, :enoent, _} -> IO.puts "Media directory not found. Skipping..."
      {:ok, _} -> nil
    end
  end

  defp genpage(content, ctx) do
    content
    |> basehtml(ctx ++ [navigation: getcfg(:navstub)])
  end

  defp getcfg(key), do: Application.get_env(:serum, key, "")

  defp dowstr(n) do
    case n do
      1 -> "Monday"
      2 -> "Tuesday"
      3 -> "Wednesday"
      4 -> "Thursday"
      5 -> "Friday"
      6 -> "Saturday"
      7 -> "Sunday"
    end
  end

  defp monabbr(n) do
    case n do
      1 -> "Jan"
      2 -> "Feb"
      3 -> "Mar"
      4 -> "Apr"
      5 -> "May"
      6 -> "Jun"
      7 -> "Jul"
      8 -> "Aug"
      9 -> "Sep"
      10 -> "Oct"
      11 -> "Nov"
      12 -> "Dec"
    end
  end

  defp mkmeta([h|t], l) do
    url = "#{getcfg :base_url}posts/#{h}.html"
    [year, month, day|_] = String.split(h, "-") |> Enum.map(fn x ->
      case Integer.parse(x) do
        {x, _} -> x
        :error -> nil
      end
    end)
    title = File.open!("#{@src_posts}#{h}.md", [:read], fn device -> IO.gets device, "" end)
            |> String.trim
            |> String.replace(~r/^# /, "")
    mkmeta(t, l ++ [%Serum.Postmeta{
      title: title,
      date: "#{day} #{monabbr month} #{year}",
      file: url
    }])
  end

  defp mkmeta([], l), do: l
end
