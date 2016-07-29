defmodule Hyde do
  require EEx

  @templates "templates/"
  @src_posts "posts/"
  @build_posts "site-build/posts/"
  @posts "site/posts/"

  EEx.function_from_file :defp, :listhtml, @templates <> "list.html.eex", [:posts]
  EEx.function_from_file :defp, :posthtml, @templates <> "post.html.eex", [:contents, :author, :title, :date]
  EEx.function_from_file :defp, :basehtml, @templates <> "base.html.eex", [:contents, :page_title, :site_name, :site_description]

  def build_posts() do
    files = File.ls!(@src_posts) |> Enum.filter(&(String.ends_with? &1, ".md"))
    IO.puts "Cleaning directory `#{@build_posts}`..."
    File.rm_rf! @build_posts
    File.mkdir_p! @build_posts
    IO.puts "Cleaning directory `#{@posts}`..."
    File.rm_rf! @posts
    File.mkdir_p! @posts

    IO.puts "Generating metadata..."
    metalist = mkmeta(files, [])
    File.open!("#{@build_posts}metadata.json", [:write], fn device ->
      IO.write device, Poison.encode!(metalist)
    end)

    Enum.each files, fn x ->
      [year, month, day|_] = String.split(x, "-") |> Enum.map(fn x ->
        case Integer.parse(x) do
          {int, _} -> int
          :error -> nil
        end
      end)
      out = "#{@build_posts}#{x}.html"
      IO.puts "  MD2HTML  #{@src_posts}#{x} -> #{out}"
      file = File.open!(out, [:write])
      [title|lines] = File.read!(@src_posts <> x) |> String.split("\n")
      title = title |> String.trim |> String.replace(~r/^# /, "")
      IO.write file, Earmark.to_html(lines)
      File.close file

      x = x <> ".html"
      out = @posts <> String.replace(x, ".md", "")
      IO.puts "  GEN  #{@build_posts}#{x} -> #{out}"
      file = File.open!(out, [:write])
      dow = dowstr :calendar.day_of_the_week(year, month, day)
      datestr = "#{dow}, #{day} #{monabbr month} #{year}"
      res = File.read!(@build_posts <> x)
            |> posthtml(getcfg(:author), title, datestr)
            |> basehtml("#{getcfg(:site_name)} - #{title}", getcfg(:site_name), getcfg(:site_description))
      IO.write file, res
      File.close file
    end

    IO.puts "Generating posts index..."
    File.open!("#{@posts}index.html", [:write], fn device ->
      res = listhtml(metalist)
            |> basehtml("#{getcfg(:site_name)} - All Posts", getcfg(:site_name), getcfg(:site_description))
      IO.write device, res
    end)
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
    out = "#{getcfg :base_url}posts/#{String.replace h, ".md", ".html"}"
    [year, month, day|_] = String.split(h, "-") |> Enum.map(fn x ->
      case Integer.parse(x) do
        {x, _} -> x
        :error -> nil
      end
    end)
    dow = dowstr :calendar.day_of_the_week(year, month, day)
    title = File.open!("#{@src_posts}#{h}", [:read], fn device -> IO.gets device, "" end)
            |> String.trim
            |> String.replace(~r/^# /, "")
    mkmeta(t, l ++ [%Hyde.Postmeta{
      title: title,
      date: "#{dow}, #{day} #{monabbr month} #{year}",
      file: out
    }])
  end

  defp mkmeta([], l), do: l
end
