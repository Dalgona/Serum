defmodule Serum.Build do
  @moduledoc """
  This module contains functions for generating pages of your website.
  """

  import Serum.Util
  alias Serum.Error
  alias Serum.BuildPass1, as: Pass1
  alias Serum.BuildPass2, as: Pass2
  alias Serum.Renderer
  alias Serum.TemplateLoader

  @type mode :: :parallel | :sequential
  @type template_ast :: Macro.t | nil
  @type state :: map

  @spec build(mode, state) :: Error.result(binary)

  def build(mode, state) do
    with :ok <- check_dest_perm(state.dest),
         :ok <- check_tz(),
         :ok <- clean_dest(state.dest),
         {:ok, state2} <- build_pass1(mode, state),
         {:ok, state3} <- prepare_templates(state2),
         :ok <- build_pass2(mode, state3) do
      copy_assets state3
      {:ok, state3}
    else
      {:error, _, _} = error -> error
    end
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
    {result1, result2} = {Task.await(t1), Task.await(t2)}
    with {:ok, page_info} <- result1,
         {:ok, post_info} <- result2 do
      state =
        state
        |> Map.put(:page_info, page_info)
        |> Map.put(:post_info, post_info)
      {:ok, state}
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
      {:ok, state}
    else
      {:error, _, _} = error -> error
    end
  end

  @spec prepare_templates(state) :: Error.result(state)

  defp prepare_templates(state) do
    with {:ok, templates} <- TemplateLoader.load_templates(state),
         template_nav = templates["nav"],
         {:ok, nav} <- Renderer.render_stub(template_nav, [], "nav") do
      new_state =
        state
        |> Map.put(:templates, templates)
        |> Map.put(:includes, %{"nav" => nav})
      {:ok, new_state}
    else
      {:error, _, _} = error -> error
    end
  end

  @spec build_pass2(mode, state) :: Error.result

  defp build_pass2(:parallel, state) do
    t1 = Task.async fn -> Pass2.PageBuilder.run :parallel, state end
    t2 = Task.async fn -> Pass2.PostBuilder.run :parallel, state end
    {result1, result2} = {Task.await(t1), Task.await(t2)}
    with :ok <- result1,
         {:ok, post_info} <- result2 do
      state = %{state|post_info: post_info}
      t3 = Task.async fn -> Pass2.IndexBuilder.run :parallel, state end
      Task.await t3
    else
      {:error, _, _} = error -> error
    end
  end

  defp build_pass2(:sequential, state) do
    page_result = Pass2.PageBuilder.run :sequential, state
    post_result = Pass2.PostBuilder.run :sequential, state
    with :ok <- page_result,
         {:ok, post_info} <- post_result do
      state = %{state|post_info: post_info}
      Pass2.IndexBuilder.run :sequential, state
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
