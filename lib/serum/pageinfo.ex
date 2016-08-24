defmodule Serum.Pageinfo do
  @moduledoc """
  This module defines Pageinfo struct.
  """

  @derive [Poison.Encoder]
  defstruct [:name, :type, :title, :menu, :menu_text, :menu_icon]
end
