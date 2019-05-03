defmodule Serum.IncompatiblePlugin do
  @behaviour Serum.Plugin

  def name, do: "incompatible_plugin"
  def version, do: "0.1.0"

  # Change this when Elixir 99.99.99 is released.
  def elixir, do: "> 99.99.99"

  # Change this when Serum 99.99.99 is released.
  def serum, do: "> 99.99.99"

  def description, do: "This is an incompatible Serum plugin."

  def implements, do: []
end
