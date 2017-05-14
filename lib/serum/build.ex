defmodule Serum.Build do
  @moduledoc """
  This module contains functions for generating pages of your website.
  """

  import Serum.Util
  alias Serum.Error
  alias Serum.Build.Preparation
  alias Serum.Build.{PageBuilder, PostBuilder, IndexBuilder, Renderer}
  alias Serum.BuildPass1, as: Pass1

  @type mode :: :parallel | :sequential
  @type template_ast :: Macro.t | nil
  @type state ::
    %{project_info: map, build_data: map, src: binary, dest: binary}

  @spec build(mode, state) :: Error.result(binary)

  def build(mode, state) do
    with :ok <- check_dest_perm(state.dest),
         :ok <- check_tz(),
         :ok <- clean_dest(state.dest),
         {:ok, new_state} <- build_pass1(mode, state) do
      IO.inspect new_state
    else
      {:error, _, _} = error -> error
    end
#    with :ok <- check_dest_perm(state.dest),
#         {:ok, state2} <- prepare_build(state),
#         {:ok, dest} <- do_build(mode, state2) do
#      {:ok, dest}
#    else
#      {:error, _, _} = error -> error
#    end
  end

  @spec check_dest_perm(binary) :: Error.result

  defp check_dest_perm(dest) do
    parent = dest |> String.replace_suffix("/", "") |> :filename.dirname
    result =
      case File.stat parent do
        {:error, reason} -> reason
        {:ok, %File.Stat{access: :none}} -> :eacces
        {:ok, %File.Stat{access: :read}} -> :eacces
        {:ok, _} -> :ok
      end
    case result do
      :ok -> :ok
      err -> {:error, :file_error, {err, dest, 0}}
    end
  end

  @spec check_tz() :: Error.result

  defp check_tz() do
    try do
      Timex.local()
      :ok
    rescue
      _ -> {:error, :system_error, "system timezone is not set"}
    end
  end

  @spec clean_dest(binary) :: :ok

  defp clean_dest(dest) do
    File.mkdir_p! "#{dest}"
    IO.puts "Created directory `#{dest}`."

    # exclude dotfiles so that git repository is not blown away
    dest
    |> File.ls!
    |> Enum.filter(&(not String.starts_with?(&1, ".")))
    |> Enum.map(&("#{dest}#{&1}"))
    |> Enum.each(&File.rm_rf!(&1))
  end

  @spec build_pass1(mode, state) :: Error.result(state)

  defp build_pass1(:parallel, state) do
    t1 = Task.async fn -> Pass1.PageBuilder.run :parallel, state end
    t2 = Task.async fn -> Pass1.PostBuilder.run :parallel, state end
    with {:ok, page_info} <- Task.await(t1),
         {:ok, post_info} <- Task.await(t2) do
      state =
        state
        |> Map.put(:page_info, page_info)
        |> Map.put(:post_info, post_info)
      t3 = Task.async fn -> Pass1.IndexBuilder.run :parallel, state end
      {:ok, tags} = Task.await t3
      {:ok, Map.put(state, :tags, tags)}
    else
      {:error, _, _} = error -> error
    end
  end

  defp build_pass1(:sequential, state) do
    with {:ok, page_info} <- Pass1.PageBuilder.run(:parallel, state),
         {:ok, post_info} <- Pass1.PostBuilder.run(:parallel, state) do
      state =
        state
        |> Map.put(:page_info, page_info)
        |> Map.put(:post_info, post_info)
      {:ok, tags} = Pass1.IndexBuilder.run :parallel, state
      {:ok, Map.put(state, :tags, tags)}
    else
      {:error, _, _} = error -> error
    end
  end

  @spec prepare_build(state) :: Error.result(state)

  defp prepare_build(state) do
    IO.puts "Rebuilding Website..."
    prep_results =
      [:load_templates]
      |> Enum.map(fn fun -> apply Preparation, fun, [state] end)
      |> Error.filter_results_with_values(:build_preparation)
    with {:ok, [templates]} <- prep_results,
         template_nav = templates["template__nav"],
         {:ok, nav} <- Renderer.render_stub(template_nav, [], "nav") do
      build_data =
        state.build_data
        |> Map.merge(templates)
        |> Map.put("navstub", nav)
      {:ok, %{state|build_data: build_data}}
    else
      {:error, _, _} = error -> error
    end
  end

  @spec do_build(mode, state) :: Error.result(binary)

  defp do_build(mode, state) do
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

  @spec compile_nav(template_ast) :: binary

  defp compile_nav(template) do
    IO.puts "Compiling main navigation HTML stub..."
    Renderer.render_stub template, []
  end

  @spec launch_tasks(mode, state) :: Error.result

  defp launch_tasks(:parallel, state) do
    IO.puts "\u26a1  \x1b[1mStarting parallel build...\x1b[0m"
    t1 = Task.async fn -> PageBuilder.run :parallel, state end
    t2 = Task.async fn -> PostBuilder.run :parallel, state end
    with :ok <- Task.await(t1),
         {:ok, posts} <- Task.await(t2) do
      build_data = state.build_data
      state = %{state|build_data: Map.put(build_data, "all_posts", posts)}
      t3 = Task.async fn -> IndexBuilder.run :parallel, state end
      Task.await t3
    else
      {:error, _, _} = error -> error
    end
  end

  defp launch_tasks(:sequential, state) do
    IO.puts "\u231b  \x1b[1mStarting sequential build...\x1b[0m"
    page_result = PageBuilder.run :sequential, state
    post_result = PostBuilder.run :sequential, state
    with :ok <- page_result,
         {:ok, posts} <- post_result do
      build_data = state.build_data
      state = %{state|build_data: Map.put(build_data, "all_posts", posts)}
      IndexBuilder.run :sequential, state
    else
      {:error, _, _} = error -> error
    end
  end

  @spec copy_assets(state) :: :ok

  defp copy_assets(%{src: src, dest: dest}) do
    IO.puts "Copying assets and media..."
    try_copy "#{src}assets/", "#{dest}assets/"
    try_copy "#{src}media/", "#{dest}media/"
  end

  @spec try_copy(binary, binary) :: :ok

  defp try_copy(src, dest) do
    case File.cp_r src, dest do
      {:error, reason, _} ->
        warn "Cannot copy #{src}: #{:file.format_error(reason)}. Skipping."
      {:ok, _} -> :ok
    end
  end
end
