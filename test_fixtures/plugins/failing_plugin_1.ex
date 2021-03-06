defmodule Serum.FailingPlugin1 do
  @behaviour Serum.Plugin

  def name, do: "failing_plugin_1"
  def version, do: "0.1.0"
  def elixir, do: ">= 1.6.0"
  def serum, do: ">= 0.9.0"
  def description, do: "This plugin always raises an error."

  def implements, do: [
    build_started: 3,
    reading_pages: 2,
    reading_posts: 2,
    reading_templates: 2,
    reading_includes: 2,
    processing_page: 2,
    processing_template: 2,
    build_succeeded: 3,
    finalizing: 3
  ]

  def build_started(_src, _dest, _args) do
    raise "test: build_started"
  end

  def reading_posts(_files, _args) do
    raise "test: reading_posts"
  end

  def processing_page(_file, _args) do
    {:error, "test: processing_page"}
  end

  def finalizing(_src, _dest, _args) do
    {:error, "test: finalizing"}
  end

  def processing_template(_file, _args) do
    "oh, really?"
  end

  def build_succeeded(_src, _dest, _args) do
    "i am glad the build has completed successfully"
  end
end
