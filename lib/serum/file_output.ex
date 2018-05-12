defmodule Serum.FileOutput do
  @moduledoc """
  Defines a struct representing a file to be written.

  ## Fields

  * `src`: Source path
  * `dest`: Destination path
  * `data`: Data to be written to a file
  """

  @type t :: %__MODULE__{
          src: binary(),
          dest: binary(),
          data: binary()
        }

  defstruct [:src, :dest, :data]

  @doc "Actually writes a file described by the given `FileOutput` struct."
  @spec perform_output!(t()) :: :ok
  def perform_output!(output) do
    File.open!(output.dest, [:write, :utf8], fn file ->
      IO.write(file, output.data)
    end)

    put_msg(output.src, output.dest)
  end

  @spec put_msg(binary(), binary()) :: :ok
  defp put_msg(src, dest)

  defp put_msg(nil, dest) do
    IO.puts("\x1b[92m  GEN  \x1b[0m#{dest}")
  end

  defp put_msg(src, dest) do
    IO.puts("\x1b[92m  GEN  \x1b[0m#{src} -> #{dest}")
  end
end
