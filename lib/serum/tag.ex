defmodule Serum.Tag do
  @moduledoc "This module defines Tag struct."

  @type t :: %__MODULE__{}

  defstruct [:name, :list_url]

  @spec new(binary(), map()) :: t()
  def new(name, proj) do
    %__MODULE__{
      name: name,
      list_url: Path.join([proj.base_url, "tags", name, "index.html"])
    }
  end

  @spec batch_create([binary()] | nil, map()) :: [t()]
  def batch_create(names, proj)

  def batch_create(nil, _proj), do: []
  def batch_create([], _proj), do: []

  def batch_create([_h | _t] = names, proj) do
    names |> Enum.sort() |> Enum.map(&new(&1, proj))
  end
end

defimpl Inspect, for: Serum.Tag do
  def inspect(tag, _opts), do: ~s(#Serum.Tag<"#{tag.name}": "#{tag.list_url}">)
end
