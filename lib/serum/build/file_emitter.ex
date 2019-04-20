defmodule Serum.Build.FileEmitter do
  @moduledoc """
  Renders each fragment into a full HTML page and writes to a file.
  """

  alias Serum.Plugin
  alias Serum.Result

  @spec run([Serum.File.t()]) :: Result.t()
  def run(files) do
    IO.puts("Writing output files...")
    create_dirs(files)

    files
    |> Enum.map(&write_file/1)
    |> Result.aggregate(:file_emitter)
  end

  @spec create_dirs([Serum.File.t()]) :: :ok
  defp create_dirs(outputs) do
    outputs
    |> Stream.map(& &1.dest)
    |> Stream.map(&Path.dirname/1)
    |> Stream.uniq()
    |> Enum.each(fn dir ->
      File.mkdir_p!(dir)
      IO.puts("\x1b[96m MKDIR \x1b[0m#{dir}")
    end)
  end

  @spec write_file(Serum.File.t()) :: Result.t()
  defp write_file(file) do
    case Serum.File.write(file) do
      {:ok, ^file} -> Plugin.wrote_file(file)
      {:error, _} = error -> error
    end
  end
end
