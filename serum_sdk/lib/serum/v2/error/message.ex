defmodule Serum.V2.Error.Message do
  @moduledoc "A behaviour that every error message structs must implement."

  @type t :: struct()

  @doc "Creates an error message struct from the given arguments."
  @callback message(args :: [term()]) :: t()
end
