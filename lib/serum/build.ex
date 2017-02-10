defmodule Serum.Build do
  @moduledoc """
  This module contains functions for generating pages of your website.
  """

  import Serum.Util
  alias Serum.Error
  alias Serum.BuildDataStorage
  alias Serum.ProjectInfoStorage
  alias Serum.Build.Preparation
  alias Serum.Build.{PageBuilder, PostBuilder, IndexBuilder, Renderer}

  @type build_mode :: :parallel | :sequential
  @type compiled_template :: tuple
  @type state :: %{project_info: map, build_data: map}

  @spec build(String.t, String.t, build_mode) :: Error.result(String.t)

  def build(src, dest, mode) do
    case check_access dest do
      :ok -> do_build_stage1 src, dest, mode
      err -> {:error, :file_error, {err, dest, 0}}
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

  @spec do_build_stage1(String.t, String.t, build_mode)
    :: Error.result(String.t)

  defp do_build_stage1(src, dest, mode) do
    IO.puts "Rebuilding Website..."
    BuildDataStorage.init self()
    BuildDataStorage.put self(), "pages_file", []

    clean_dest dest
    prep_results =
      [check_tz: [], load_templates: [src], scan_pages: [src, dest]]
      |> Enum.map(fn {fun, args} -> apply Preparation, fun, args end)
      |> Error.filter_results(:build_preparation)
    case prep_results do
      :ok ->
        # TODO: prettify codes or change storage apis
        proj_info = ProjectInfoStorage.all self()
        build_data = Agent.get {:via, Registry, {Serum.Registry, {:build_data, self()}}}, &(&1)
        state = %{
          project_info: proj_info,
          build_data: Map.put(
            build_data,
            "navstub",
            compile_nav(build_data["template__nav"])
          )
        }
        do_build_stage2 src, dest, mode, state
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

  @spec do_build_stage2(String.t, String.t, build_mode, state)
    :: Error.result(String.t)

  defp do_build_stage2(src, dest, mode, state) do
    {time, result} =
      :timer.tc fn ->
        launch_tasks mode, src, dest, state
      end
    case result do
      :ok ->
        IO.puts "Build process took #{time/1000}ms."
        copy_assets src, dest
        {:ok, dest}
      error -> error
    end
  end

  @spec compile_nav(compiled_template) :: binary

  defp compile_nav(template) do
    IO.puts "Compiling main navigation HTML stub..."
    Renderer.render template, []
  end

  @spec launch_tasks(build_mode, String.t, String.t, state) :: Error.result

  defp launch_tasks(:parallel, src, dest, state) do
    IO.puts "\u26a1  \x1b[1mStarting parallel build...\x1b[0m"
    t1 = Task.async fn -> PageBuilder.run :parallel, src, dest, state end
    t2 = Task.async fn -> PostBuilder.run :parallel, src, dest, state end
    page_result = Task.await t1
    post_result = Task.await t2
    case post_result do
      {:ok, posts} ->
        build_data = state.build_data
        state = %{state|build_data: Map.put(build_data, "all_posts", posts)}
        t3 = Task.async fn -> IndexBuilder.run :parallel, src, dest, state end
        index_result = Task.await t3
        Error.filter_results [page_result, index_result], :launch_tasks
      _ ->
        Error.filter_results [page_result, post_result], :launch_tasks
    end
  end

  defp launch_tasks(:sequential, src, dest, state) do
    IO.puts "\u231b  \x1b[1mStarting sequential build...\x1b[0m"
    page_result = PageBuilder.run :sequential, src, dest, state
    post_result = PostBuilder.run :sequential, src, dest, state
    case post_result do
      {:ok, posts} ->
        build_data = state.build_data
        state = %{state|build_data: Map.put(build_data, "all_posts", posts)}
        index_result = IndexBuilder.run :sequential, src, dest, state
        Error.filter_results [page_result, index_result], :launch_tasks
      _ ->
        Error.filter_results [page_result, post_result], :launch_tasks
    end
  end

  @spec copy_assets(String.t, String.t) :: :ok

  defp copy_assets(src, dest) do
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
