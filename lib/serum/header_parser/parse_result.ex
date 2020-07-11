defmodule Serum.HeaderParser.ParseResult do
  @moduledoc false

  _moduledocp = """
  A struct containing a result of Serum.HeaderParser.parse_header/3 function.

  ## Fields

  - `data` - a map containing values of recognized keys.
  - `extras` - a map containing values of other (unrecognized) keys. Every keys
    and values are parsed as binaries.
  - `rest` - rest of the input data, right after the end of the parsed header.
  - `next_line` - line number of the first line of `rest`. This piece of
    information can be provided to another compiler or parser as a line offset.
  """

  @type t :: %__MODULE__{
          data: %{optional(atom()) => term()},
          extras: %{optional(binary()) => binary()},
          rest: binary(),
          next_line: non_neg_integer()
        }

  defstruct data: %{},
            extras: %{},
            rest: "",
            next_line: 0
end
