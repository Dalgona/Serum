defmodule Serum.V2.Error.ConstraintMessage do
  @moduledoc "A struct containing constraint check failure message."

  @behaviour Serum.V2.Error.Message

  defstruct [:name, :value, :constraint]

  @type t :: %__MODULE__{
          name: String.Chars.t(),
          value: term(),
          constraint: binary()
        }

  @impl true
  @spec message([term()]) :: t()
  def message([name, value, constraint]) when is_binary(constraint) do
    %__MODULE__{name: name, value: value, constraint: constraint}
  end
end
