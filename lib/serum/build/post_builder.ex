defmodule Serum.Build.PostBuilder do
  @moduledoc """
  This module contains functions for building blog posts
  sequantially for parallelly.
  """

  alias Serum.Error
  alias Serum.Build
  alias Serum.Build.Renderer

  @default_date_format    "{YYYY}-{0M}-{0D}"
  @default_preview_length 200

  @spec run(String.t, String.t, Build.build_mode) :: Error.result
  def run(src, dest, mode) do
    srcdir = "#{src}posts/"
    dstdir = "#{dest}posts/"
    Agent.update(Serum.PostInfoStorage, fn _ -> [] end)

    try do
      files = load_file_list(srcdir)
      File.mkdir_p!(dstdir)

      result = launch(mode, files, srcdir, dstdir)
      case Enum.filter(result, &(&1 != :ok)) do
        [] -> :ok
        errors when is_list(errors) -> {:error, :child_tasks, errors}
      end
    rescue
      e in File.Error ->
        {:error, :file_error, {Exception.message(e), e.path, 0}}
    end
  end

  @spec load_file_list(String.t) :: [String.t]
  @raises [File.Error]
  defp load_file_list(srcdir) do
    ls =
      for x <- File.ls!(srcdir), String.ends_with?(x, ".md") do
        String.replace x, ~r/\.md$/, ""
      end
    Enum.sort ls
  end

  @spec launch(Build.build_mode, [String.t], String.t, String.t) :: [Error.result]
  defp launch(:parallel, files, srcdir, dstdir) do
    files
    |> Enum.map(&(Task.async __MODULE__, :post_task, [srcdir, dstdir, &1]))
    |> Enum.map(&Task.await&1)
  end

  defp launch(:sequential, files, srcdir, dstdir) do
    files
    |> Enum.map(&(post_task srcdir, dstdir, &1))
  end

  @spec post_task(String.t, String.t, String.t) :: Error.result
  def post_task(srcdir, dstdir, file) do
    proj = Serum.get_data :proj

    srcname = "#{srcdir}#{file}.md"
    dstname = "#{dstdir}#{file}.html"

    try do
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
      :ok
    rescue
      e in File.Error ->
        {:error, :file_error, {Exception.message(e), e.path, 0}}
      e in Serum.PostError ->
        {:error, :post_error, {Exception.message(e), e.path, 0}}
    end
  end

  # TODO: preview_length should be validated before this function is run.
  #       (this must be an integer value)
  @spec make_preview(String.t) :: String.t
  defp make_preview(html) do
    proj = Serum.get_data :proj
    maxlen = Keyword.get(proj, :preview_length) || @default_preview_length
    case maxlen do
      0 -> ""
      x when is_integer(x) ->
        parsed =
          case Floki.parse(html) do
            t when is_tuple(t) -> [t]
            l when is_list(l)  -> l
          end
        parsed
        |> Enum.filter(&(elem(&1, 0) == "p"))
        |> Enum.map(&(Floki.text elem(&1, 2)))
        |> Enum.join(" ")
        |> String.slice(0, x)
    end
  end

  @spec render_post(String.t, %Serum.Postinfo{}) :: String.t
  defp render_post(contents, info) do
    template = Serum.get_data "template_post"
    template
    |> Renderer.render([title: info.title, date: info.date,
      tags: info.tags, contents: contents])
    |> Renderer.genpage([page_title: info.title])
  end

  @spec extract_date(String.t) :: String.t
  @raises [Serum.PostError]
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
        raise Serum.PostError, reason: :filename, path: filename
    end
  end

  @spec extract_header(String.t) :: {String.t, String.t, String.t}
  @raises [File.Error, Serum.PostError]
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
        raise Serum.PostError, reason: :header, path: filename
    end
  end
end
