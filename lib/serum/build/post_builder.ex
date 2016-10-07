defmodule Serum.Build.PostBuilder do
  alias Serum.Build.Renderer

  @default_date_format    "{YYYY}-{0M}-{0D}"
  @default_preview_length 200

  def run(src, dest, mode) do
    {:ok, _pid} = Agent.start_link fn -> [] end, name: Serum.Build.PostInfoStorage

    srcdir = "#{src}posts/"
    dstdir = "#{dest}posts/"
    proj = Agent.get Global, &(Map.get &1, :proj)

    files = load_file_list srcdir
    File.mkdir_p! dstdir

    Enum.each launch_post(mode, files, srcdir, dstdir), &Task.await&1
    infolist = Serum.Build.PostInfoStorage
           |> Agent.get(&(&1))
           |> Enum.sort_by(&(&1.file))

    IO.puts "Generating posts index..."
    template_list = Agent.get Global, &(Map.get &1, "template_list")
    File.open! "#{dstdir}index.html", [:write, :utf8], fn device ->
      html = template_list
             |> Renderer.render(proj ++ [header: "All Posts", posts: Enum.reverse infolist])
             |> Renderer.genpage(proj ++ [page_title: "All Posts"])
      IO.write device, html
    end

    tagmap = generate_tagmap infolist
    Enum.each launch_tag(mode, tagmap, dest), &Task.await&1

    Agent.stop Serum.Build.PostInfoStorage
  end

  defp load_file_list(srcdir) do
    ls =
      for x <- File.ls!(srcdir), String.ends_with?(x, ".md") do
        String.replace x, ~r/\.md$/, ""
      end
    Enum.sort ls
  end

  defp generate_tagmap(infolist) do
    Enum.reduce infolist, %{}, fn m, a ->
      tmp = Enum.reduce m.tags, %{}, &(Map.put &2, &1, (Map.get &2, &1, []) ++ [m])
      Map.merge a, tmp, fn _, u, v -> MapSet.to_list(MapSet.new u ++ v) end
    end
  end

  defp launch_post(:parallel, files, srcdir, dstdir) do
    files
    |> Enum.map(&(Task.async __MODULE__, :post_task, [srcdir, dstdir, &1]))
  end

  defp launch_post(:sequential, files, srcdir, dstdir) do
    files
    |> Enum.each(&(post_task srcdir, dstdir, &1))
    []
  end

  defp launch_tag(:parallel, tagmap, dir) do
    tagmap
    |> Enum.map(&(Task.async __MODULE__, :tag_task, [dir, &1]))
  end

  defp launch_tag(:sequential, tagmap, dir) do
    tagmap
    |> Enum.each(&(tag_task dir, &1))
    []
  end

  def post_task(srcdir, dstdir, file) do
    proj = Agent.get Global, &(Map.get &1, :proj)

    srcname = "#{srcdir}#{file}.md"
    dstname = "#{dstdir}#{file}.html"

    [l1, l2|lines] = srcname |> File.read! |> String.split("\n")
    {title, tags} = extract_header srcname, {l1, l2}

    stub = lines |> Earmark.to_html
    preview = make_preview stub

    datetime = extract_date srcname

    info = %Serum.Postinfo{
      file: file, title: title, date: datetime, tags: tags,
      url: "#{Keyword.get proj, :base_url}posts/#{file}.html",
      preview_text: preview
    }
    Agent.update Serum.Build.PostInfoStorage, &([info|&1])

    html = stub |> render_post(info)

    File.open! dstname, [:write, :utf8], &(IO.write &1, html)
    IO.puts "  GEN  #{srcname} -> #{dstname}"
  end

  defp make_preview(html) do
    proj = Agent.get Global, &(Map.get &1, :proj)
    maxlen = Keyword.get(proj, :preview_length) || @default_preview_length
    case maxlen do
      0 -> ""
      x when is_integer x ->
        html
        |> Floki.parse
        |> Enum.filter(&(elem(&1, 0) == "p"))
        |> Enum.map(&(Floki.text elem(&1, 2)))
        |> Enum.join(" ")
        |> String.slice(0, x)
      _ ->
        raise MatchError, message: "preview_length must be an integer"
    end
  end

  defp render_post(contents, info) do
    template = Agent.get Global, &(Map.get &1, "template_post")
    template
    |> Renderer.render([title: info.title, date: info.date,
      tags: info.tags, contents: contents])
    |> Renderer.genpage([page_title: info.title])
  end

  def tag_task(dest, {k, v}) do
    template = Agent.get Global, &(Map.get &1, "template_list")
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

  defp mkinfo_fail(srcname, reason) do
    IO.puts "\x1b[31mError while parsing `#{srcname}.md`: #{reason}\x1b[0m"
    exit "error while building blog posts"
  end

  defp extract_date(filename) do
    proj = Agent.get Global, &(Map.get &1, :proj)
    try do
      [filename|_] = filename |> String.split("/") |> Enum.reverse
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
      {{y, m, d}, {h, i, 0}}
      |> Timex.to_datetime(:local)
      |> Timex.format!(Keyword.get(proj, :date_format) || @default_date_format)
    rescue
      _ in MatchError ->
        mkinfo_fail filename, :invalid_filename
    end
  end

  defp extract_header(filename, header) do
    proj = Agent.get Global, &(Map.get &1, :proj)
    try do
      {"# " <> title, "#" <> tags} = header
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
        mkinfo_fail filename, :invalid_header
    end
  end
end
