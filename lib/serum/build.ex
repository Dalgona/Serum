defmodule Serum.Build do
  @moduledoc """
  This module contains functions for actually building a Serum project.
  """

  import Serum.Util
  alias Serum.Error
  alias Serum.Build.Pass1
  alias Serum.Build.Pass2
  alias Serum.Template
  alias Serum.TemplateLoader

  @type mode :: :parallel | :sequential
  @type state :: map

  @doc """
  Starts building the website in given build mode (parallel or sequential).

  This function does the followings:

  1. Checks if the effective user has a write permission to the output
    directory.
  2. Checks if the system timezone is properly set. Timex application relies on
    the system timezone to format the date string. So if the system timezone is
    not set, Timex will fail.
  3. Cleans the output directory. However, files or directories starting with a
    dot (`'.'`) will not be deleted, as these may contain important version
    control stuff and so on.
  4. Launches 2-pass build process. Refer to `Serum.Build.Pass1` and
    `Serum.Build.Pass2` for more information about 2-pass build process.
  5. Finally copies `assets/` and `media/` directory to the output directory
    (if any).
  """
  @spec build(mode, state) :: Error.result(binary)

  def build(mode, state) do
    with :ok <- check_dest_perm(state.project_info.dest),
         :ok <- check_tz(),
         :ok <- clean_dest(state.project_info.dest),
         :ok <- prepare_templates(state.project_info.src),
         {:ok, output} <- Pass1.run(mode, state.project_info),
         state = wip_update_state(state, output),
         :ok <- Pass2.run(mode, state)
    do
      copy_assets(state.project_info.src, state.project_info.dest)
      {:ok, state}
    else
      {:error, _} = error -> error
    end
  end

  defp wip_update_state(state, output) do
    site_ctx =
      state.project_info
      |> Map.from_struct()
      |> Keyword.new()
      |> Keyword.put(:pages, output.pages)
      |> Keyword.put(:posts, output.posts)
      |> Keyword.put(:tags, output.tag_counts)
    state
    |> Map.put(:site_ctx, site_ctx)
    |> Map.put(:tag_map, output.tag_map)
  end

  # Checks if the effective user have a write
  # permission on the destination directory.
  @spec check_dest_perm(binary) :: Error.result

  defp check_dest_perm(dest) do
    parent = dest |> Path.join("") |> Path.dirname()
    result =
      case File.stat parent do
        {:error, reason} -> reason
        {:ok, %File.Stat{access: :none}} -> :eacces
        {:ok, %File.Stat{access: :read}} -> :eacces
        {:ok, _} -> :ok
      end
    case result do
      :ok -> :ok
      err -> {:error, {err, dest, 0}}
    end
  end

  # Checks if the system timezone is set and valid.
  @spec check_tz() :: Error.result

  defp check_tz() do
    try do
      Timex.local()
      :ok
    rescue
      _ -> {:error, "system timezone is not set"}
    end
  end

  # Removes all files and directories in the destination directory,
  # excluding dotfiles so that git repository is not blown away.
  @spec clean_dest(binary) :: :ok

  defp clean_dest(dest) do
    File.mkdir_p! dest
    msg_mkdir dest

    dest
    |> File.ls!
    |> Enum.reject(&String.starts_with?(&1, "."))
    |> Enum.map(&Path.join(dest, &1))
    |> Enum.each(&File.rm_rf!(&1))
  end

  @spec prepare_templates(binary()) :: Error.result()

  defp prepare_templates(src) do
    with :ok <- TemplateLoader.load_includes(src),
         :ok <- TemplateLoader.load_templates(src)
    do
      :ok
    else
      {:error, _} = error -> error
    end
  end

  @spec copy_assets(binary(), binary()) :: :ok

  defp copy_assets(src, dest) do
    IO.puts "Copying assets and media..."
    try_copy Path.join(src, "assets"), Path.join(dest, "assets")
    try_copy Path.join(src, "media"), Path.join(dest, "media")
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
