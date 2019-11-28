defmodule Serum.Build.FileCopier do
  @moduledoc false

  import Serum.IOProxy, only: [put_msg: 2, put_err: 2]
  alias Serum.Result
  alias Serum.Theme

  @doc false
  @spec copy_files(binary(), binary()) :: Result.t({})
  def copy_files(src, dest) do
    case copy_theme_assets(dest) do
      :ok ->
        copy_assets(src, dest)
        do_copy_files(src, dest)

      {:error, _} = error ->
        error
    end
  end

  @spec copy_theme_assets(binary()) :: Result.t({})
  defp copy_theme_assets(dest) do
    case Theme.get_assets() do
      {:ok, false} -> :ok
      {:ok, path} -> try_copy(path, Path.join(dest, "assets"))
      {:error, _} = error -> error
    end
  end

  @spec copy_assets(binary(), binary()) :: :ok
  defp copy_assets(src, dest) do
    put_msg(:info, "Copying assets and media...")
    try_copy(Path.join(src, "assets"), Path.join(dest, "assets"))
    try_copy(Path.join(src, "media"), Path.join(dest, "media"))
  end

  @spec do_copy_files(binary(), binary()) :: :ok
  defp do_copy_files(src, dest) do
    files_dir = Path.join(src, "files")

    if File.exists?(files_dir), do: try_copy(files_dir, dest), else: :ok
  end

  @spec try_copy(binary(), binary()) :: :ok
  defp try_copy(src, dest) do
    case File.cp_r(src, dest) do
      {:error, reason, _} ->
        put_err(:warn, "Cannot copy #{src}: #{:file.format_error(reason)}. Skipping.")

      {:ok, _} ->
        :ok
    end
  end
end
