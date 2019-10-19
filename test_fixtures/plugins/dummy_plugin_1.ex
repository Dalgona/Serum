defmodule Serum.DummyPlugin1 do
  @behaviour Serum.Plugin

  def name, do: "dummy_plugin_1"
  def version, do: "0.0.1"
  def elixir, do: ">= 1.6.0"
  def serum, do: ">= 0.10.0"
  def description, do: "This is dummy plugin no. 1"

  def implements do
    [
      build_started: 3,
      reading_posts: 2,
      processing_page: 2,
      processing_template: 2,
      processed_post: 2,
      processed_list: 2,
      rendered_page: 2,
      build_succeeded: 3,
      finalizing: 3
    ]
  end

  def build_started(src, dest, _args) do
    debug("build_started: #{src}, #{dest}")
  end

  def reading_posts(files, _args) do
    debug("reading_posts: #{length(files)}")

    {:ok, files}
  end

  def processing_page(file, _args) do
    debug("processing_page: #{file.src}")

    {:ok, file}
  end

  def processing_template(file, _args) do
    debug("processing_template: #{file.src}")

    {:ok, file}
  end

  def processed_post(post, _args) do
    debug("processed_post: #{post.title}")

    {:ok, post}
  end

  def processed_list(list, _args) do
    debug("processed_list: #{list.title}")

    {:ok, list}
  end

  def rendered_page(file, _args) do
    debug("rendered_page: #{file.dest}")

    {:ok, file}
  end

  def build_succeeded(src, dest, _args) do
    debug("build_succeeded: #{src}, #{dest}")
  end

  def finalizing(src, dest, _args) do
    debug("finalizing: #{src}, #{dest}")
  end

  defp debug(msg), do: IO.puts("\x1b[90m#{name()} #{msg}\x1b[0m")
end
