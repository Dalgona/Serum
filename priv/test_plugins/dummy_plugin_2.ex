defmodule Serum.DummyPlugin2 do
  @behaviour Serum.Plugin

  def name, do: "dummy_plugin_2"
  def version, do: "0.0.1"
  def elixir, do: ">= 1.6.0"
  def serum, do: ">= 0.10.0"
  def description, do: "This is dummy plugin no. 2"

  def implements do
    [
      :build_started,
      :reading_pages,
      :processing_page,
      :processing_post,
      :processed_post,
      :processed_template,
      :rendered_page,
      :wrote_file,
      :finalizing
    ]
  end

  def build_started(src, dest) do
    debug("build_started: #{src}, #{dest}")
  end

  def reading_pages(files) do
    debug("reading_pages: #{length(files)}")

    {:ok, files}
  end

  def processing_page(file) do
    debug("processing_page: #{file.src}")

    {:ok, file}
  end

  def processing_post(file) do
    debug("processing_post: #{file.src}")

    {:ok, file}
  end

  def processed_post(post) do
    debug("processed_post: #{post.title}")

    {:ok, post}
  end

  def processed_template(template) do
    debug("processed_template: #{template.file}")

    {:ok, template}
  end

  def rendered_page(file) do
    debug("rendered_page: #{file.dest}")

    {:ok, file}
  end

  def wrote_file(file) do
    debug("wrote_file: #{file.dest}")
  end

  def finalizing(src, dest) do
    debug("finalizing: #{src}, #{dest}")
  end

  defp debug(msg), do: IO.puts("\x1b[90m#{name()} #{msg}\x1b[0m")
end
