defmodule Serum.FailingPlugin1 do
  use Serum.V2.Plugin
  alias Serum.V2.Error
  alias Serum.V2.Error.SimpleMessage

  def name, do: "failing_plugin_1"
  def version, do: "0.1.0"
  def description, do: "This plugin does not work well"

  def implements, do: [
    build_started: 2,
    build_succeeded: 2,
    build_failed: 3,
    reading_pages: 2,
    reading_posts: 2,
    reading_templates: 2
  ]

  # Failure type 1: raising an error
  def build_started(_project, _state) do
    raise "test: build_started"
  end

  # Failure type 2: returning `{:error, %Serum.V2.Error{}}`
  def build_succeeded(_project, _state) do
    {:error,
     %Error{
       message: %SimpleMessage{text: "test: build_succeeded"},
       caused_by: []
     }}
  end

  # Failure type 3: returning an unexpected value
  def build_failed(_project, _result, _state) do
    123
  end

  # Failure type 1
  def reading_pages(_paths, _state) do
    raise "teste: reading_pages"
  end

  # Failure type 2
  def reading_posts(_paths, _state) do
    {:error,
     %Error{
       message: %SimpleMessage{text: "test: reading_posts"},
       caused_by: []
     }}
  end

  # Failure type 3
  def reading_templates(_paths, _state) do
    456
  end
end
