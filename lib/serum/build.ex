defmodule Serum.Build do
  @moduledoc """
  This module contains functions for generating pages of your website.
  """

  import Serum.Util
  alias Serum.Error
  alias Serum.Build.Pass1
  alias Serum.Build.Pass2
  alias Serum.TemplateLoader

  @type mode :: :parallel | :sequential
  @type template_ast :: Macro.t | nil
  @type state :: map

  @spec build(mode, state) :: Error.result(binary)

  def build(mode, state) do
    with :ok <- check_dest_perm(state.dest),
         :ok <- check_tz(),
         :ok <- clean_dest(state.dest),
         {:ok, state2} <- Pass1.run(mode, state),
         {:ok, state3} <- prepare_templates(state2),
         :ok <- Pass2.run(mode, state3)
    do
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

  @spec prepare_templates(state) :: Error.result(state)

  defp prepare_templates(state) do
    with {:ok, state2} <- TemplateLoader.load_includes(state),
         {:ok, state3} <- TemplateLoader.load_templates(state2)
    do
      {:ok, state3}
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
