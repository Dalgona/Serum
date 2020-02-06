defmodule Serum.V2.File do
  @moduledoc """
  A struct representing a file to be read or written.

  ## Fields

  * `src` - source path
  * `dest` - destination path
  * `in_data` - data read from a file
  * `out_data` - data to be written to a file
  """

  require Serum.V2.Result, as: Result

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

    Result.fail(Simple: [msg])
  end

  def read(%__MODULE__{src: src} = file) do
    case File.read(src) do
      {:ok, data} when is_binary(data) ->
        Result.return(%__MODULE__{file | in_data: data})

      {:error, reason} ->
        Result.fail(POSIX: [reason], file: file)
    end
  end

  @doc """
  Writes data to a file described by the given `Serum.File` struct.

  An error will be returned if `dest` is `nil`.
  """
  @spec write(t()) :: Result.t(t())
  def write(%__MODULE__{dest: nil}) do
    msg = "a Serum.File struct with 'dest = nil' cannot be used with Serum.File.write/1"

    Result.fail(Simple: [msg])
  end

  def write(%__MODULE__{dest: dest, out_data: data} = file) do
    case File.open(dest, [:write, :utf8], &IO.write(&1, data)) do
      {:ok, _} ->
        Result.return(file)

      {:error, reason} ->
        Result.fail(POSIX: [reason], file: file)
    end
  end
end
