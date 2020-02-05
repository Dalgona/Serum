defmodule Serum.Build do
  @moduledoc """
  A module for managing the overall project build procedure.
  """

  import Serum.IOProxy, only: [put_msg: 2]
  require Serum.Result, as: Result
  alias Serum.Build.FileCopier
  alias Serum.Build.FileEmitter
  alias Serum.Build.FileLoader
  alias Serum.Build.FileProcessor
  alias Serum.Build.FragmentGenerator
  alias Serum.Build.PageGenerator
  alias Serum.Error
  alias Serum.Plugin
  alias Serum.Plugin.Client, as: PluginClient
  alias Serum.Project
  alias Serum.Theme

  @doc """
  Builds the given Serum project.

  ## Build Procedure

  1. Tries to load plugins and a theme.

  2. Checks if the system timezone is properly set.

      Timex requires the local timezone information to format the date/time
      string. If it's not set or invalid, Timex will fail.

  3. Checks if the current user has enough permission on the destination
    directory and cleans it if it already exists.

  4. Loads source files. See `Serum.Build.FileLoader`.

  5. Processes source files and produces intermediate data structures.
    See `Serum.Build.FileProcessor`.

  6. Generates HTML fragments from the intermediate data.
    See `Serum.Build.FragmentGenerator`.

  7. Renders full HTML pages from fragments and writes them to files.
    See `Serum.Build.FileEmitter`.

  8. Copies `assets/` and `media/` directories if they exist.
  """
  @spec build(Project.t()) :: Result.t(binary())
  def build(%Project{src: src, dest: dest} = proj) do
    Result.run do
      proj <- load_plugins(proj)
      PluginClient.build_started(src, dest)
      pre_check(dest)
      do_build(proj)
      PluginClient.build_succeeded(src, dest)
      PluginClient.finalizing(src, dest)

      Result.return(dest)
    end
    |> case do
      {:ok, _} = result ->
        result

      {:error, %Error{}} = error ->
        Result.run do
          PluginClient.build_failed(src, dest, error)
          PluginClient.finalizing(src, dest)

          error
        end
    end
  end

  @spec load_plugins(Project.t()) :: Result.t(Project.t())
  defp load_plugins(proj) do
    Result.run do
      plugins <- Plugin.load_plugins(proj.plugins)
      theme <- Theme.load(proj.theme.module)
      Plugin.show_info(plugins)

      Result.return(%Project{proj | theme: theme})
    end
  end

  @spec pre_check(binary()) :: Result.t({})
  defp pre_check(dest) do
    Result.run do
      check_tz()
      check_dest_perm(dest)
      clean_dest(dest)

      Result.return()
    end
  end

  @spec do_build(Project.t()) :: Result.t({})
  defp do_build(%{src: src, dest: dest} = proj) do
    Result.run do
      files <- FileLoader.load_files(src)
      map <- FileProcessor.process_files(files, proj)
      fragments <- FragmentGenerator.to_fragment(map)
      generated_files <- PageGenerator.run(fragments)
      FileEmitter.run(generated_files)
      FileCopier.copy_files(src, dest)
    end
  end

  # Checks if the system timezone is set and valid.
  @spec check_tz() :: Result.t({})
  defp check_tz do
    Timex.local()
    Result.return()
  rescue
    _ -> Result.fail(Simple: ["system timezone is not set"])
  end

  # Checks if the effective user have a write
  # permission on the destination directory.
  @spec check_dest_perm(binary()) :: Result.t({})
  defp check_dest_perm(dest) do
    dest
    |> Path.join("")
    |> Path.dirname()
    |> File.stat()
    |> case do
      {:error, reason} -> reason
      {:ok, %File.Stat{access: :none}} -> :eacces
      {:ok, %File.Stat{access: :read}} -> :eacces
      {:ok, _} -> :ok
    end
    |> case do
      :ok -> Result.return()
      err -> Result.fail(POSIX: [err], file: %Serum.File{src: dest})
    end
  end

  # Removes all files and directories in the destination directory,
  # excluding dotfiles so that git repository is not blown away.
  @spec clean_dest(binary()) :: Result.t([{}])
  defp clean_dest(dest) do
    File.mkdir_p!(dest)
    put_msg(:mkdir, dest)

    dest
    |> File.ls!()
    |> Enum.reject(&String.starts_with?(&1, "."))
    |> Enum.map(&Path.join(dest, &1))
    |> Enum.map(fn path ->
      case File.rm_rf(path) do
        {:ok, _} -> Result.return()
        {:error, reason, ^path} -> Result.fail(POSIX: [reason], file: %Serum.File{src: path})
      end
    end)
    |> Result.aggregate("failed to clean the destination directory:")
  end
end
