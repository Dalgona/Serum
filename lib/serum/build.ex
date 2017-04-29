defmodule Serum.Build do
  @moduledoc """
  This module contains functions for generating pages of your website.
  """

  import Serum.Util
  alias Serum.Error
  alias Serum.Build.Preparation
  alias Serum.Build.{PageBuilder, PostBuilder, IndexBuilder, Renderer}

  @type mode :: :parallel | :sequential
  @type compiled_template :: tuple | nil
  @type state ::
    %{project_info: map, build_data: map, src: String.t, dest: String.t}

  @spec build(mode, state) :: Error.result(String.t)

  def build(mode, state) do
    case check_access state.dest do
      :ok -> do_build_stage1 mode, state
      err -> {:error, :file_error, {err, state.dest, 0}}
    end
  end

  @spec check_access(String.t) :: :ok | File.posix

  defp check_access(dest) do
    parent = dest |> String.replace_suffix("/", "") |> :filename.dirname
    case File.stat parent do
      {:error, reason} -> reason
      {:ok, %File.Stat{access: :none}} -> :eacces
      {:ok, %File.Stat{access: :read}} -> :eacces
      {:ok, _} -> :ok
    end
  end

  @spec do_build_stage1(mode, state) :: Error.result(String.t)

  defp do_build_stage1(mode, state) do
    IO.puts "Rebuilding Website..."

    clean_dest state.dest
    prep_results =
      [:check_tz, :load_templates, :scan_pages]
      |> Enum.map(fn fun -> apply Preparation, fun, [state] end)
      |> Error.filter_results_with_values(:build_preparation)
    case prep_results do
      {:ok, [nil, templates, pages]} ->
        # TODO: wrap this line with case
        {:ok, nav} = Renderer.render_stub templates["template__nav"], [], "nav"
        build_data =
          state.build_data
          |> Map.merge(templates)
          |> Map.merge(pages)
          |> Map.put("navstub", nav)
        state = %{state|build_data: build_data}
        do_build_stage2 mode, state
      error -> error
    end
  end

  @spec clean_dest(String.t) :: :ok

  defp clean_dest(dest) do
    File.mkdir_p! "#{dest}"
    IO.puts "Created directory `#{dest}`."

    # exclude dotfiles so that git repository is not blown away
    dest |> File.ls!
         |> Enum.filter(&(not String.starts_with?(&1, ".")))
         |> Enum.map(&("#{dest}#{&1}"))
         |> Enum.each(&File.rm_rf!(&1))
  end

  @spec do_build_stage2(mode, state) :: Error.result(String.t)

  defp do_build_stage2(mode, state) do
    {time, result} =
      :timer.tc fn ->
        launch_tasks mode, state
      end
    case result do
      :ok ->
        IO.puts "Build process took #{time/1000}ms."
        copy_assets state
        {:ok, state.dest}
      error -> error
    end
  end

  @spec compile_nav(compiled_template) :: binary

  defp compile_nav(template) do
    IO.puts "Compiling main navigation HTML stub..."
    Renderer.render_stub template, []
  end

  @spec launch_tasks(mode, state) :: Error.result

  defp launch_tasks(:parallel, state) do
    IO.puts "\u26a1  \x1b[1mStarting parallel build...\x1b[0m"
    t1 = Task.async fn -> PageBuilder.run :parallel, state end
    t2 = Task.async fn -> PostBuilder.run :parallel, state end
    page_result = Task.await t1
    post_result = Task.await t2
    case post_result do
      {:ok, posts} ->
        build_data = state.build_data
        state = %{state|build_data: Map.put(build_data, "all_posts", posts)}
        t3 = Task.async fn -> IndexBuilder.run :parallel, state end
        index_result = Task.await t3
        Error.filter_results [page_result, index_result], :launch_tasks
      _ ->
        Error.filter_results [page_result, post_result], :launch_tasks
    end
  end

  defp launch_tasks(:sequential, state) do
    IO.puts "\u231b  \x1b[1mStarting sequential build...\x1b[0m"
    page_result = PageBuilder.run :sequential, state
    post_result = PostBuilder.run :sequential, state
    case post_result do
      {:ok, posts} ->
        build_data = state.build_data
        state = %{state|build_data: Map.put(build_data, "all_posts", posts)}
        index_result = IndexBuilder.run :sequential, state
        Error.filter_results [page_result, index_result], :launch_tasks
      _ ->
        Error.filter_results [page_result, post_result], :launch_tasks
    end
  end

  @spec copy_assets(state) :: :ok

  defp copy_assets(%{src: src, dest: dest}) do
    IO.puts "Copying assets and media..."
    try_copy "#{src}assets/", "#{dest}assets/"
    try_copy "#{src}media/", "#{dest}media/"
  end

  @spec try_copy(String.t, String.t) :: :ok

  defp try_copy(src, dest) do
    case File.cp_r src, dest do
      {:error, reason, _} ->
        warn "Cannot copy #{src}: #{:file.format_error(reason)}. Skipping."
      {:ok, _} -> :ok
    end
  end
end
