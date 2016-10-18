defmodule Serum.Build.PostBuilder do
  alias Serum.Build.Renderer

  @default_date_format    "{YYYY}-{0M}-{0D}"
  @default_preview_length 200

  def run(src, dest, mode) do
    srcdir = "#{src}posts/"
    dstdir = "#{dest}posts/"
    Agent.update(Serum.PostInfoStorage, fn _ -> [] end)

    files = load_file_list(srcdir)
    File.mkdir_p!(dstdir)

    Enum.each launch_post(mode, files, srcdir, dstdir), &Task.await&1
  end

  defp load_file_list(srcdir) do
    ls =
      for x <- File.ls!(srcdir), String.ends_with?(x, ".md") do
        String.replace x, ~r/\.md$/, ""
      end
    Enum.sort ls
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

  def post_task(srcdir, dstdir, file) do
    proj = Serum.get_data :proj

    srcname = "#{srcdir}#{file}.md"
    dstname = "#{dstdir}#{file}.html"

    {title, tags, lines} = extract_header(srcname)
    datetime = extract_date(srcname)

    stub = Earmark.to_html(lines)
    preview = make_preview(stub)

    info = %Serum.Postinfo{
      file: file, title: title, date: datetime, tags: tags,
      url: "#{Keyword.get proj, :base_url}posts/#{file}.html",
      preview_text: preview
    }
    Agent.update Serum.PostInfoStorage, &([info|&1])

    html = render_post(stub, info)
    File.open! dstname, [:write, :utf8], &(IO.write &1, html)
    IO.puts "  GEN  #{srcname} -> #{dstname}"
  end

  defp make_preview(html) do
    proj = Serum.get_data :proj
    maxlen = Keyword.get(proj, :preview_length) || @default_preview_length
    case maxlen do
      0 -> ""
      x when is_integer(x) ->
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
    template = Serum.get_data "template_post"
    template
    |> Renderer.render([title: info.title, date: info.date,
      tags: info.tags, contents: contents])
    |> Renderer.genpage([page_title: info.title])
  end

  defp mkinfo_fail(srcname, reason) do
    IO.puts "\x1b[31mError while parsing `#{srcname}`: #{reason}\x1b[0m"
    exit "error while building blog posts"
  end

  defp extract_date(filename) do
    proj = Serum.get_data :proj
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

  defp extract_header(filename) do
    proj = Serum.get_data :proj
    try do
      [l1, l2|rest] = filename |> File.read! |> String.split("\n")
      {"# " <> title, "#" <> tags} = {l1, l2}
      title = String.trim(title)
      tags = tags |> String.split(~r/, ?/)
                  |> Enum.filter(&(String.trim(&1) != ""))
                  |> Enum.map(fn x ->
                    tag = String.trim x
                    %{name: tag, list_url: "#{Keyword.get proj, :base_url}tags/#{tag}/"}
                  end)
      {title, tags, rest}
    rescue
      _ in MatchError ->
        mkinfo_fail filename, :invalid_header
    end
  end
end
