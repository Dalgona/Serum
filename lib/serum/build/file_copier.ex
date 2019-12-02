defmodule Serum.Build.FileCopier do
  @moduledoc false

  require Serum.Result, as: Result
  import Serum.IOProxy, only: [put_msg: 2, put_err: 2]
  alias Serum.Error
  alias Serum.Theme

  @doc false
  @spec copy_files(binary(), binary()) :: Result.t({})
  def copy_files(src, dest) do
    Result.run do
      copy_theme_assets(dest)
      copy_assets(src, dest)
      do_copy_files(src, dest)
    end
  end

  @spec copy_theme_assets(binary()) :: Result.t({})
  defp copy_theme_assets(dest) do
    case Theme.get_assets() do
      {:ok, false} -> Result.return()
      {:ok, path} -> try_copy(path, Path.join(dest, "assets"))
      {:error, %Error{}} = error -> error
    end
  end

  @spec copy_assets(binary(), binary()) :: Result.t({})
  defp copy_assets(src, dest) do
    put_msg(:info, "Copying assets and media...")
    try_copy(Path.join(src, "assets"), Path.join(dest, "assets"))
    try_copy(Path.join(src, "media"), Path.join(dest, "media"))
  end

  @spec do_copy_files(binary(), binary()) :: Result.t({})
  defp do_copy_files(src, dest) do
    files_dir = Path.join(src, "files")

    if File.exists?(files_dir), do: try_copy(files_dir, dest), else: Result.return()
  end

  @spec try_copy(binary(), binary()) :: Result.t({})
  defp try_copy(src, dest) do
    case File.cp_r(src, dest) do
      {:error, reason, _} ->
        put_err(:warn, "Cannot copy #{src}: #{:file.format_error(reason)}. Skipping.")

      {:ok, _} ->
        Result.return()
    end
  end
end
