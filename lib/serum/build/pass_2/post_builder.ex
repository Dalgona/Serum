defmodule Serum.Build.Pass2.PostBuilder do
  @moduledoc """
  During pass 2, PostBuilder does the following:

  1. Loops through the list of all blog posts. Renders the full HTML page of a
    blog post for each `Serum.PostInfo` object in the list.
  """

  import Serum.Util
  alias Serum.Error
  alias Serum.Build
  alias Serum.Renderer
  alias Serum.PostInfo

  @type state :: Build.state

  @async_opt [max_concurrency: System.schedulers_online * 10]

  @doc "Starts the second pass of PostBuilder."
  @spec run(Build.mode, state) :: Error.result

  def run(mode, state) do
    postdir = Path.join state.dest, "posts"
    File.mkdir_p! postdir
    msg_mkdir postdir
    result = launch mode, state.site_ctx[:posts], state
    Error.filter_results result, :post_builder
  end

  @spec launch(Build.mode, [PostInfo.t], state) :: [Error.result]

  defp launch(:parallel, files, state) do
    files
    |> Task.async_stream(__MODULE__, :post_task, [state], @async_opt)
    |> Enum.map(&(elem &1, 1))
  end

  defp launch(:sequential, files, state) do
    files |> Enum.map(&post_task(&1, state))
  end

  @doc false
  @spec post_task(PostInfo.t, state) :: Error.result

  def post_task(info, state) do
    srcpath = info.file
    destpath = info.output
    case render_post info, state do
      {:ok, html} ->
        fwrite destpath, html
        msg_gen srcpath, destpath
        :ok
      {:error, _} = error -> error
    end
  end

  @spec render_post(PostInfo.t, state) :: Error.result(binary)

  defp render_post(info, state) do
    post_ctx = [
      title: info.title, date: info.date, raw_date: info.raw_date,
      tags: info.tags, contents: info.html
    ]
    Renderer.render "post", post_ctx, [page_title: info.title], state
  end
end
