defmodule Serum.V2.Tag do
  @moduledoc """
  A struct containing tag information.

  ## Fields

  - `name` - Name of the tag.
  - `url` - Absolute url of where post list pages for this tag are located.
  """

  defstruct [:name, :url]

  @type t :: %__MODULE__{name: binary(), url: binary()}
end
