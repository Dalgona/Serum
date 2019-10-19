defmodule Serum.OldPlugin do
  @behaviour Serum.Plugin

  def name, do: "old_plugin"
  def version, do: "0.0.1"
  def elixir, do: ">= 1.6.0"
  def serum, do: ">= 0.10.0"
  def description, do: "This plugin implements obsolete callbacks."
  def implements, do: [:build_started, build_succeeded: 2]

  def build_started(src, dest) do
    debug("build_started: #{src}, #{dest}")
  end

  def build_succeeded(src, dest) do
    debug("build_succeeded: #{src}, #{dest}")
  end

  defp debug(msg), do: IO.puts("\x1b[90m#{name()} #{msg}\x1b[0m")
end
