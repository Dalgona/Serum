defmodule Hyde.Postmeta do
  @derive [Poison.Encoder]
  defstruct [:title, :date, :file]
end
