defmodule Serum.DummyPlugin1 do
  @behaviour Serum.Plugin

  def name, do: "dummy_plugin_1"
  def version, do: "0.0.1"
  def elixir, do: ">= 1.6.0"
  def serum, do: "~> 0.9.0"
  def description, do: "This is dummy plugin no. 1"

  def implements do
    [
      :build_started,
      :reading_posts,
      :processing_page,
      :processing_template,
      :processed_post,
      :processed_list,
      :rendered_page,
      :build_succeeded,
      :finalizing
    ]
  end

  def build_started(src, dest) do
    debug("build_started: #{src}, #{dest}")
  end

  def reading_posts(files) do
    debug("reading_posts: #{length(files)}")

    {:ok, files}
  end

  def processing_page(file) do
    debug("processing_page: #{file.src}")

    {:ok, file}
  end

  def processing_template(file) do
    debug("processing_template: #{file.src}")

    {:ok, file}
  end

  def processed_post(post) do
    debug("processed_post: #{post.title}")

    {:ok, post}
  end

  def processed_list(list) do
    debug("processed_list: #{list.title}")

    {:ok, list}
  end

  def rendered_page(file) do
    debug("rendered_page: #{file.dest}")

    {:ok, file}
  end

  def build_succeeded(src, dest) do
    debug("build_succeeded: #{src}, #{dest}")
  end

  def finalizing(src, dest) do
    debug("finalizing: #{src}, #{dest}")
  end

  defp debug(msg), do: IO.puts("\x1b[90m#{name()} #{msg}\x1b[0m")
end
