defmodule Serum.Build.PostBuilder do
  @moduledoc """
  This module contains functions for building blog posts
  sequantially for parallelly.
  """

  import Serum.Util
  alias Serum.Error
  alias Serum.Build
  alias Serum.Build.Renderer

  @typep header :: {String.t, [Serum.Tag.t], [String.t]}

  @default_date_format    "{YYYY}-{0M}-{0D}"
  @default_preview_length 200
  @re_fname ~r/^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}-[0-9a-z\-]+$/

  @spec run(String.t, String.t, Build.build_mode) :: Error.result
  def run(src, dest, mode) do
    srcdir = "#{src}posts/"
    dstdir = "#{dest}posts/"
    Agent.update Serum.PostInfoStorage, fn _ -> [] end

    case load_file_list srcdir do
      {:ok, list} ->
        File.mkdir_p! dstdir
        result = launch mode, list, srcdir, dstdir
        Error.filter_results result, :post_builder
      error -> error
    end
  end

  @spec load_file_list(String.t) :: Error.result([String.t])
  defp load_file_list(srcdir) do
    case File.ls srcdir do
      {:ok, list} ->
        list =
          list
          |> Enum.filter_map(&String.ends_with?(&1, ".md"), fn x ->
            String.replace x, ~r/\.md$/, ""
          end)
          |> Enum.sort
        {:ok, list}
      {:error, reason} ->
        {:error, :file_error, {reason, srcdir, 0}}
    end
  end

  @spec launch(Build.build_mode, [String.t], String.t, String.t)
    :: [Error.result]
  defp launch(:parallel, files, srcdir, dstdir) do
    files
    |> Enum.map(&Task.async(__MODULE__, :post_task, [srcdir, dstdir, &1]))
    |> Enum.map(&Task.await/1)
  end

  defp launch(:sequential, files, srcdir, dstdir) do
    files
    |> Enum.map(&post_task(srcdir, dstdir, &1))
  end

  @spec post_task(String.t, String.t, String.t) :: Error.result
  def post_task(srcdir, dstdir, file) do
    srcname = "#{srcdir}#{file}.md"
    dstname = "#{dstdir}#{file}.html"
    case {extract_date(srcname), extract_header(srcname)} do
      {{:ok, datestr}, {:ok, header}} ->
        do_post_task file, srcname, dstname, header, datestr
      {error = {:error, _, _}, _} -> error
      {_, error = {:error, _, _}} -> error
    end
  end

  @spec do_post_task(String.t, String.t, String.t, header, String.t) :: :ok
  defp do_post_task(file, srcname, dstname, header, datestr) do
    base = Serum.get_data "proj", "base_url"
    {title, tags, lines} = header
    stub = Earmark.to_html lines
    preview = make_preview stub
    info = %Serum.Postinfo{
      file: file, title: title, date: datestr, tags: tags,
      url: "#{base}posts/#{file}.html",
      preview_text: preview
    }
    Agent.update Serum.PostInfoStorage, &([info|&1])
    html = render_post stub, info
    fwrite dstname, html
    IO.puts "  GEN  #{srcname} -> #{dstname}"
    :ok
  end

  @spec make_preview(String.t) :: String.t
  defp make_preview(html) do
    maxlen = Serum.get_data("proj", "preview_length") || @default_preview_length
    case maxlen do
      0 -> ""
      x when is_integer(x) ->
        parsed =
          case Floki.parse html do
            t when is_tuple(t) -> [t]
            l when is_list(l)  -> l
          end
        parsed
        |> Enum.filter(&(elem(&1, 0) == "p"))
        |> Enum.map(&Floki.text(elem &1, 2))
        |> Enum.join(" ")
        |> String.slice(0, x)
    end
  end

  @spec render_post(String.t, Serum.Postinfo.t) :: String.t
  defp render_post(contents, info) do
    template = Serum.get_data "template", "post"
    template
    |> Renderer.render([title: info.title, date: info.date,
      tags: info.tags, contents: contents])
    |> Renderer.genpage([page_title: info.title])
  end

  @spec extract_date(String.t) :: Error.result(String.t)
  defp extract_date(path) do
    fname = :filename.basename path, ".md"
    if fname =~ @re_fname do
      [y, m, d, hhmm|_] =
        fname
        |> String.split("-")
        |> Enum.take(4)
        |> Enum.map(&(&1 |> Integer.parse |> elem(0)))
      datefmt =
        Serum.get_data("proj", "date_format") || @default_date_format
      {h, i} =
        with h <- div(hhmm, 100), i <- rem(hhmm, 100) do
          h = h > 23 && 23 || h
          i = i > 59 && 59 || i
          {h, i}
        end
      datestr =
        {{y, m, d}, {h, i, 0}}
        |> Timex.to_datetime(:local)
        |> Timex.format!(datefmt)
      {:ok, datestr}
    else
      {:error, :post_error, {:invalid_filename, path, 0}}
    end
  end

  @spec extract_header(String.t) :: Error.result(header)
  defp extract_header(fname) do
    base = Serum.get_data "proj", "base_url"
    case File.read fname do
      {:ok, data} ->
        do_extract_header fname, base, data
      {:error, reason} ->
        {:error, :file_error, {reason, fname, 0}}
    end
  end

  @spec do_extract_header(String.t, String.t, String.t) :: Error.result(header)
  defp do_extract_header(fname, base, data) do
    try do
      [l1, l2|rest] = data |> String.split("\n")
      {"# " <> title, "#" <> tags} = {l1, l2}
      title = String.trim title
      tags =
        tags
        |> String.split(~r/, */)
        |> Stream.map(&String.trim/1)
        |> Stream.reject(&(&1 == ""))
        |> Enum.sort
        |> Enum.map(&(%Serum.Tag{name: &1, list_url: "#{base}tags/#{&1}"}))
      {:ok, {title, tags, rest}}
    rescue
      _ in MatchError ->
        {:error, :post_error, {:invalid_header, fname, 0}}
    end
  end
end
