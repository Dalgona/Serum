defmodule Serum.V2.File do
  @moduledoc """
  A struct representing a file to be read or written.

  ## Fields

  * `src` - source path
  * `dest` - destination path
  * `in_data` - data read from a file
  * `out_data` - data to be written to a file
  """

  defstruct [:src, :dest, :in_data, :out_data]

  @type t :: %__MODULE__{
          src: binary() | nil,
          dest: binary() | nil,
          in_data: IO.chardata() | String.Chars.t() | nil,
          out_data: IO.chardata() | String.Chars.t() | nil
        }
end
