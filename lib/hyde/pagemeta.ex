defmodule Hyde.Pagemeta do
  @derive [Poison.Encoder]
  defstruct [:name, :title, :menu, :menu_text, :menu_icon]
end
