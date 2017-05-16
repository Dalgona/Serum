defmodule Serum.BuildPass2.PostBuilder do
  @moduledoc """
  This module contains functions for building blog posts
  sequantially for parallelly.
  """

  import Serum.Util
  alias Serum.Error
  alias Serum.Build
  alias Serum.Renderer
  alias Serum.PostInfo

  @type state :: Build.state

  @async_opt [max_concurrency: System.schedulers_online * 10]

  @spec run(Build.mode, state) :: Error.result([PostInfo.t])

  def run(mode, state) do
    File.mkdir_p! "#{state.dest}posts/"
    result = launch mode, state.post_info, state
    Error.filter_results_with_values result, :post_builder
  end

  @spec launch(Build.mode, [PostInfo.t], state) :: [Error.result(PostInfo.t)]

  defp launch(:parallel, files, state) do
    files
    |> Task.async_stream(__MODULE__, :post_task, [state], @async_opt)
    |> Enum.map(&(elem &1, 1))
  end

  defp launch(:sequential, files, state) do
    files |> Enum.map(&post_task(&1, state))
  end

  @spec post_task(PostInfo.t, state) :: Error.result(PostInfo.t)

  def post_task(info, state) do
    srcpath = info.file
    destpath =
      srcpath
      |> String.replace_prefix(state.src, state.dest)
      |> String.replace_suffix(".md", ".html")
    case File.open srcpath, [:read, :utf8] do
      {:ok, file} ->
        _ = IO.read file, :line
        _ = IO.read file, :line
        data = IO.read file, :all
        File.close file
        htmlstub = Earmark.to_html data
        preview = make_preview htmlstub, state.project_info.preview_length
        case render_post htmlstub, info, state do
          {:ok, html} ->
            fwrite destpath, html
            IO.puts "  GEN  #{srcpath} -> #{destpath}"
            {:ok, %PostInfo{info|preview_text: preview}}
          {:error, _, _} = error -> error
        end
      {:error, reason} ->
        {:error, :file_error, {reason, srcpath, 0}}
    end
  end

  @spec make_preview(binary, non_neg_integer) :: binary

  def make_preview(html, maxlen) do
    case maxlen do
      0 -> ""
      x when is_integer(x) ->
        parsed =
          case Floki.parse html do
            t when is_tuple(t) -> [t]
            l when is_list(l)  -> l
          end
        parsed
        |> Enum.filter_map(&(elem(&1, 0) == "p"), &Floki.text/1)
        |> Enum.join(" ")
        |> String.slice(0, x)
    end
  end

  @spec render_post(binary, PostInfo.t, state) :: Error.result(binary)

  defp render_post(contents, info, state) do
    post_ctx = [
      title: info.title, date: info.date, raw_date: info.raw_date,
      tags: info.tags, contents: contents
    ]
    Renderer.render "post", post_ctx, [page_title: info.title], state
  end
end
