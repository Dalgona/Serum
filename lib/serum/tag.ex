defmodule Serum.Tag do
  @moduledoc "This module defines Tag struct."

  @type t :: %__MODULE__{}

  defstruct [:name, :list_url]
end

defimpl Inspect, for: Serum.Tag do
  def inspect(tag, _opts), do: ~s(#Serum.Tag<"#{tag.name}": "#{tag.list_url}">)
end
