defmodule Serum.Build.FileEmitter do
  @moduledoc false

  _moduledocp = """
  A module responsible for writing each complete HTML page to a file.
  """

  require Serum.Result, as: Result
  import Serum.IOProxy, only: [put_msg: 2]
  alias Serum.Error
  alias Serum.Plugin.Client, as: PluginClient

  @doc """
  Write files described by `%Serum.File{}` to actual files on disk.

  Necessary subdirectories will be created if they don't exist.
  """
  @spec run([Serum.File.t()]) :: Result.t([{}])
  def run(files) do
    put_msg(:info, "Writing output files...")

    case create_dirs(files) do
      {:ok, _} ->
        files
        |> Enum.map(&write_file/1)
        |> Result.aggregate_values("failed to write files:")

      {:error, %Error{}} = error ->
        error
    end
  end

  @spec create_dirs([Serum.File.t()]) :: Result.t([{}])
  defp create_dirs(outputs) do
    outputs
    |> Stream.map(& &1.dest)
    |> Stream.map(&Path.dirname/1)
    |> Stream.uniq()
    |> Enum.map(&create_dir/1)
    |> Result.aggregate_values("failed to create directories:")
  end

  @spec create_dir(binary()) :: Result.t({})
  defp create_dir(dir) do
    case File.mkdir_p(dir) do
      :ok -> put_msg(:mkdir, dir)
      {:error, reason} -> Result.fail(POSIX, [reason], file: %Serum.File{src: dir})
    end
  end

  @spec write_file(Serum.File.t()) :: Result.t({})
  defp write_file(file) do
    case Serum.File.write(file) do
      {:ok, ^file} -> PluginClient.wrote_file(file)
      {:error, %Error{}} = error -> error
    end
  end
end
