defmodule Serum.Pagemeta do
  @derive [Poison.Encoder]
  defstruct [:name, :type, :title, :menu, :menu_text, :menu_icon]
end
