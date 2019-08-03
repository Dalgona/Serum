defmodule Serum.FailingPlugin1 do
  @behaviour Serum.Plugin

  def name, do: "failing_plugin_1"
  def version, do: "0.1.0"
  def elixir, do: ">= 1.6.0"
  def serum, do: ">= 0.9.0"
  def description, do: "This plugin always raises an error."

  def implements, do: [
    :build_started,
    :reading_pages,
    :reading_posts,
    :reading_templates,
    :reading_includes,
    :processing_page,
    :processing_template,
    :build_succeeded,
    :finalizing
  ]

  def build_started(_src, _dest) do
    raise "test: build_started"
  end

  def reading_posts(_files) do
    raise "test: reading_posts"
  end

  def processing_page(_file) do
    {:error, "test: processing_page"}
  end

  def finalizing(_src, _dest) do
    {:error, "test: finalizing"}
  end

  def processing_template(_file) do
    "oh, really?"
  end

  def build_succeeded(_src, _dest) do
    "i am glad the build has completed successfully"
  end
end
