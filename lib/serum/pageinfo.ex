defmodule Serum.Pageinfo do
  @derive [Poison.Encoder]
  defstruct [:name, :type, :title, :menu, :menu_text, :menu_icon]
end
