defmodule Serum.SuperWeirdTheme1 do
  def name, do: "Dummy Theme"
  def description, do: "This is a dummy theme for testing."
  def author, do: "John Doe"
  def legal, do: "Copyleft"
  def version, do: "0.1.0"
  def serum, do: ">= 1.0.0"

  def get_includes, do: "/foo/bar/baz.html.eex"
  def get_templates, do: "/foo/bar/baz.html.eex"
  def get_assets, do: 42
end
