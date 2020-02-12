defmodule Serum.V2.Tag do
  @moduledoc """
  A struct containing tag information.

  ## Fields

  - `name` - Name of the tag.
  - `path` - Absolute path of where post list pages for this tag are located.
  """

  defstruct [:name, :path]

  @type t :: %__MODULE__{name: binary(), path: binary()}
end
