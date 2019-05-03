defmodule Serum.FailingPlugin2 do
  @behaviour Serum.Plugin

  def name, do: "failing_plugin_2"
  def version, do: raise "test: version"
  def elixir, do: ">= 1.6.0"
  def serum, do: ">= 0.9.0"
  def description, do: "This plugin does not load."

  def implements, do: []
end
