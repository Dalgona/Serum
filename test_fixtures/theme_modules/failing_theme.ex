defmodule Serum.FailingTheme do
  def name, do: "Dummy Theme"
  def description, do: "This is a dummy theme for testing."
  def author, do: "John Doe"
  def legal, do: "Copyleft"
  def version, do: "0.1.0"
  def serum, do: ">= 1.0.0"

  def get_includes, do: raise "test error from get_includes/0"
  def get_templates, do: raise "test error from get_templates/0"
  def get_assets, do: raise "test error from get_assets/0"
end
