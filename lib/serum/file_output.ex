defmodule Serum.FileOutput do
  @type t :: %__MODULE__{
          src: binary(),
          dest: binary(),
          data: binary()
        }

  defstruct [:src, :dest, :data]

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
