defmodule Serum.Plugin.State do
  @moduledoc false

  _moduledocp = "A struct for storing state of `Serum.Plugin` agent."

  alias Serum.Plugin

  @type t :: %__MODULE__{states: states(), callbacks: callbacks()}
  @type states :: %{optional(module()) => term()}
  @type callbacks :: %{optional(atom()) => [{integer(), Plugin.t()}]}

  defstruct states: %{}, callbacks: %{}
end
