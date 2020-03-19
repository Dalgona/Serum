defmodule Serum.DummyPlugin2 do
  @behaviour Serum.Plugin

  def name, do: "dummy_plugin_2"
  def version, do: "0.0.1"
  def elixir, do: ">= 1.6.0"
  def serum, do: ">= 0.10.0"
  def description, do: "This is dummy plugin no. 2"

  def implements do
    [
      build_started: 3,
      reading_pages: 2,
      processing_page: 2,
      processing_post: 2,
      processed_post: 2,
      processed_template: 2,
      rendered_page: 2,
      wrote_file: 2,
      finalizing: 3
    ]
  end

  def build_started(src, dest, _args) do
    debug("build_started: #{src}, #{dest}")
  end

  def reading_pages(files, _args) do
    debug("reading_pages: #{length(files)}")

    {:ok, files}
  end

  def processing_page(file, _args) do
    debug("processing_page: #{file.src}")

    {:ok, file}
  end

  def processing_post(file, _args) do
    debug("processing_post: #{file.src}")

    {:ok, file}
  end

  def processed_post(post, _args) do
    debug("processed_post: #{post.title}")

    {:ok, post}
  end

  def processed_template(template, _args) do
    debug("processed_template: #{template.source.src}")

    {:ok, template}
  end

  def rendered_page(file, _args) do
    debug("rendered_page: #{file.dest}")

    {:ok, file}
  end

  def wrote_file(file, _args) do
    debug("wrote_file: #{file.dest}")
  end

  def finalizing(src, dest, _args) do
    debug("finalizing: #{src}, #{dest}")
  end

  defp debug(msg) do
    IO.puts("\x1b[90m#{name()} #{msg}\x1b[0m")

    {:ok, {}}
  end
end
