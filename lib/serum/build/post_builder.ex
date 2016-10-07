defmodule Serum.Build.PostBuilder do
  alias Serum.Build.Renderer

  @default_date_format    "{YYYY}-{0M}-{0D}"
  @default_preview_length 200

  def run(src, dest, mode) do
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
    File.mkdir_p! dstdir

    Enum.each launch_post(mode, files, srcdir, dstdir, template_post), &Task.await&1
    infolist = Serum.Build.PostInfoStorage
           |> Agent.get(&(&1))
           |> Enum.sort_by(&(&1.file))

    IO.puts "Generating posts index..."
    File.open! "#{dstdir}index.html", [:write, :utf8], fn device ->
      html = template_list
             |> Renderer.render(proj ++ [header: "All Posts", posts: Enum.reverse infolist])
             |> Renderer.genpage(proj ++ [page_title: "All Posts"])
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
    |> Enum.map(&(Task.async __MODULE__, :post_task, [srcdir, dstdir, &1, template]))
  end

  defp launch_post(:sequential, files, srcdir, dstdir, template) do
    files
    |> Enum.each(&(post_task srcdir, dstdir, &1, template))
    []
  end

  defp launch_tag(:parallel, tagmap, dir, template) do
    tagmap
    |> Enum.map(&(Task.async __MODULE__, :tag_task, [dir, &1, template]))
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
           |> Renderer.render([title: title, date: datetime, tags: tags, contents: stub])
           |> Renderer.genpage([page_title: title])

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
             |> Renderer.render([header: pt, posts: posts])
             |> Renderer.genpage([page_title: pt])
      IO.write device, html
    end
    IO.puts "  GEN  #{tagdir}index.html"
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
end
