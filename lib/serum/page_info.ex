defmodule Serum.PageInfo do
  defstruct [:file, :title]

  @type t :: %Serum.PageInfo{}
end

defimpl Inspect, for: Serum.PageInfo do
  def inspect(info, _opts), do: ~s(%Serum.PageInfo<"#{info.title}">)
end
