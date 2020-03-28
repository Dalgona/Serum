defmodule Serum.Build.FileEmitter do
  @moduledoc false

  _moduledocp = """
  A module responsible for writing each complete HTML page to a file.
  """

  require Serum.V2.Result, as: Result
  import Serum.V2.Console, only: [put_msg: 2]
  alias Serum.Plugin.Client, as: PluginClient
  alias Serum.V2

  @doc """
  Write files described by `Serum.V2.File` structs to actual files on disk.

  Necessary subdirectories will be created if they don't exist.
  """
  @spec run([V2.File.t()]) :: Result.t([{}])
  def run(files) do
    put_msg(:info, "Writing output files...")

    Result.run do
      create_dirs(files)
      write_files(files)
      PluginClient.wrote_files(files)
    end
  end

  @spec create_dirs([V2.File.t()]) :: Result.t([{}])
  defp create_dirs(outputs) do
    outputs
    |> Stream.map(& &1.dest)
    |> Stream.map(&Path.dirname/1)
    |> Stream.uniq()
    |> Enum.map(&create_dir/1)
    |> Result.aggregate("failed to create directories:")
  end

  @spec create_dir(binary()) :: Result.t({})
  defp create_dir(dir) do
    case File.mkdir_p(dir) do
      :ok -> put_msg(:mkdir, dir)
      {:error, reason} -> Result.fail(POSIX: [reason], file: %V2.File{src: dir})
    end
  end

  @spec write_files([V2.File.t()]) :: Result.t({})
  defp write_files(files) do
    files
    |> Enum.map(&V2.File.write/1)
    |> Result.aggregate("failed to write files:")
  end
end
