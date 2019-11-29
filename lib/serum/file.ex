defmodule Serum.File do
  @moduledoc """
  Defines a struct representing a file to be read or written.

  ## Fields

  * `src`: Source path
  * `dest`: Destination path
  * `in_data`: Data read from a file
  * `out_data`: Data to be written to a file
  """

  require Serum.Result, as: Result
  import Serum.IOProxy, only: [put_msg: 2]
  alias Serum.Error
  alias Serum.Error.POSIXMessage
  alias Serum.Error.SimpleMessage

  defstruct [:src, :dest, :in_data, :out_data]

  @type t :: %__MODULE__{
          src: binary() | nil,
          dest: binary() | nil,
          in_data: IO.chardata() | String.Chars.t() | nil,
          out_data: IO.chardata() | String.Chars.t() | nil
        }

  @doc """
  Reads data from a file described by the given `Serum.File` struct.

  An error will be returned if `src` is `nil`.
  """
  @spec read(t()) :: Result.t(t())
  def read(%__MODULE__{src: nil}) do
    msg = "a Serum.File struct with 'src = nil' cannot be used with Serum.File.read/1"

    {:error,
     %Error{
       message: %SimpleMessage{text: msg},
       caused_by: []
     }}
  end

  def read(%__MODULE__{src: src} = file) do
    case File.read(src) do
      {:ok, data} when is_binary(data) ->
        print_read(src)
        Result.return(%__MODULE__{file | in_data: data})

      {:error, reason} ->
        {:error,
         %Error{
           message: %POSIXMessage{reason: reason},
           caused_by: [],
           file: file
         }}
    end
  end

  @doc """
  Writes data to a file described by the given `Serum.File` struct.

  An error will be returned if `dest` is `nil`.
  """
  @spec write(t()) :: Result.t(t())
  def write(%__MODULE__{dest: nil}) do
    msg = "a Serum.File struct with 'dest = nil' cannot be used with Serum.File.write/1"

    {:error,
     %Error{
       message: %SimpleMessage{text: msg},
       caused_by: []
     }}
  end

  def write(%__MODULE__{dest: dest, out_data: data} = file) do
    case File.open(dest, [:write, :utf8], &IO.write(&1, data)) do
      {:ok, _} ->
        print_write(dest)
        Result.return(file)

      {:error, reason} ->
        {:error,
         %Error{
           message: %POSIXMessage{reason: reason},
           caused_by: [],
           file: file
         }}
    end
  end

  @spec print_read(binary()) :: Result.t({})
  defp print_read(src), do: put_msg(:read, src)

  @spec print_write(binary()) :: Result.t({})
  defp print_write(dest), do: put_msg(:gen, dest)
end
