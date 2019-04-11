defmodule Serum.DummyPlugin3 do
  @behaviour Serum.Plugin

  def name, do: "dummy_plugin_3"
  def version, do: "0.0.1"
  def elixir, do: ">= 1.6.0"
  def serum, do: "~> 0.9.0"
  def description, do: "This is dummy plugin no. 3"

  def implements do
    [
      :build_started,
      :reading_pages,
      :reading_posts,
      :processing_template,
      :processed_page,
      :processed_post,
      :rendered_page,
      :wrote_file,
      :build_succeeded,
    ]
  end

  def build_started(src, dest) do
    debug("build_started: #{src}, #{dest}")
  end

  def reading_pages(files) do
    debug("reading_pages: #{length(files)}")

    {:ok, files}
  end

  def reading_posts(files) do
    debug("reading_posts: #{length(files)}")

    {:ok, files}
  end

  def processing_template(file) do
    debug("processing_template: #{file.src}")

    {:ok, file}
  end

  def processed_page(page) do
    debug("processed_page: #{page.title}")

    {:ok, page}
  end

  def processed_post(post) do
    debug("processed_post: #{post.title}")

    {:ok, post}
  end

  def rendered_page(file) do
    debug("rendered_page: #{file.dest}")

    {:ok, file}
  end

  def wrote_file(file) do
    debug("wrote_file: #{file.dest}")
  end

  def build_succeeded(src, dest) do
    debug("build_succeeded: #{src}, #{dest}")
  end

  defp debug(msg), do: IO.puts("\x1b[90m#{name()} #{msg}\x1b[0m")
end
