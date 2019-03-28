defmodule Serum.File do
  alias Serum.Result

  @moduledoc """
  Defines a struct representing a file to be read or written.

  ## Fields

  * `src`: Source path
  * `dest`: Destination path
  * `in_data`: Data read from a file
  * `out_data`: Data to be written to a file
  """

  defstruct [:src, :dest, :in_data, :out_data]

  @type t :: %__MODULE__{
          src: binary(),
          dest: binary(),
          in_data: binary() | nil,
          out_data: binary() | nil
        }

  @doc "Reads data from a file described by the given `Serum.File` struct."
  @spec read(t()) :: Result.t(t())
  def read(%__MODULE__{src: src} = file) do
    case File.read(src) do
      {:ok, data} when is_binary(data) ->
        print_read(src)
        {:ok, %__MODULE__{file | in_data: data}}

      {:error, reason} ->
        {:error, {reason, src, 0}}
    end
  end

  @doc "Writes data to a file described by the given `Serum.File` struct."
  @spec write(t()) :: Result.t()
  def write(%__MODULE__{src: src, dest: dest, out_data: data}) do
    with {:ok, file} <- File.open(dest, [:write, :utf8]),
         :ok <- IO.write(file, data),
         :ok <- File.close(file) do
      print_write(src, dest)
      :ok
    else
      {:error, reason} -> {:error, {reason, dest, 0}}
    end
  end

  @spec print_read(binary()) :: :ok
  defp print_read(src) do
    IO.puts("\x1b[93m  READ \x1b[0m#{src}")
  end

  @spec print_write(binary(), binary()) :: :ok
  defp print_write(src, dest)

  defp print_write(nil, dest) do
    IO.puts("\x1b[92m   GEN \x1b[0m#{dest}")
  end

  defp print_write(src, dest) do
    IO.puts("\x1b[92m   GEN \x1b[0m#{src} -> #{dest}")
  end
end
