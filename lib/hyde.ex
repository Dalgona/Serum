defmodule Hyde do
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

  EEx.function_from_file :defp, :navhtml, @templates <> "nav.html.eex", [:pages, :assigns]
  EEx.function_from_file :defp, :listhtml, @templates <> "list.html.eex", [:posts, :assigns]
  EEx.function_from_file :defp, :posthtml, @templates <> "post.html.eex", [:contents, :title, :date, :assigns]
  EEx.function_from_file :defp, :basehtml, @templates <> "base.html.eex", [:contents, :page_title, :assigns]

  def build() do
    context = Application.get_all_env :hyde
    pagemeta = File.read!("#{@src_pages}pages.json")
               |> Poison.decode!(as: [%Hyde.Pagemeta{}])
    compile_nav pagemeta, context
    build_posts context
    build_pages pagemeta, context
    copy_assets
  end

  def compile_nav(meta, ctx) do
    IO.puts "Compiling main navigation HTML stub..."
    html = meta
           |> Enum.filter(&(&1.menu))
           |> navhtml(ctx)
    Application.put_env :hyde, :navstub, html
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
      {:ok, stub} = lines |> Enum.join("\n") |> Pandex.commonmark_to_html5
      html = stub
             |> posthtml(title, datestr, ctx)
             |> genpage(title, ctx)
      File.open!("#{@posts}#{x}.html", [:write], fn device ->
        IO.write device, html
      end)
      IO.puts "  GEN  #{@src_posts}#{x}.md -> #{@posts}#{x}.html"
    end

    IO.puts "Generating posts index..."
    File.open!("#{@posts}index.html", [:write], fn device ->
      IO.write device, (metalist |> Enum.reverse |> listhtml(ctx) |> genpage("All Posts", ctx))
    end)
  end

  def build_pages(meta, ctx) do
    IO.puts "Cleaning pages..."
    File.ls!(@pages)
    |> Enum.filter(&(String.ends_with? &1, ".html"))
    |> Enum.each(&(File.rm_rf! &1))
    Enum.each meta, fn x ->
      txt = File.read!("#{@src_pages}#{x.name}.#{x.type}")
      {_, html} = case x.type do
        "md" -> Pandex.commonmark_to_html5 txt
        "html" -> {nil, txt}
      end
      html = genpage(html, x.title, ctx)
      File.open! "#{@pages}#{x.name}.html", [:write], fn device ->
        IO.write device, html
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

  defp genpage(content, title, ctx) do
    content
    |> basehtml(title, ctx ++ [navigation: getcfg(:navstub)])
  end

  defp getcfg(key), do: Application.get_env(:hyde, key, "")

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
    mkmeta(t, l ++ [%Hyde.Postmeta{
      title: title,
      date: "#{day} #{monabbr month} #{year}",
      file: url
    }])
  end

  defp mkmeta([], l), do: l
end
