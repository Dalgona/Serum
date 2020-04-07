defmodule Serum.DummyPlugin do
  use Serum.V2.Plugin

  def name, do: "dummy_plugin"
  def version, do: "0.0.1"
  def description, do: "This is a dummy plugin."

  def implements do
    [
      build_started: 2,
      build_succeeded: 2,
      build_failed: 3,
      reading_pages: 2,
      reading_posts: 2,
      reading_templates: 2,
      processing_pages: 2,
      processing_posts: 2,
      processing_templates: 2,
      processed_pages: 2,
      processed_posts: 2,
      processed_templates: 2,
      generated_post_lists: 2,
      generating_fragment: 3,
      generated_fragment: 2,
      rendered_pages: 2,
      wrote_files: 2
    ]
  end

  def init(_) do
    Result.return(1000)
  end

  def build_started(_project, state) do
    debug("build_started/2 called")
    Result.return(state + 1)
  end

  def build_succeeded(_project, state) do
    debug("build_succeeded/2 called")
    Result.return(state + 1)
  end

  def build_failed(_project, _result, state) do
    debug("build_failed/3 called")
    Result.return(state + 1)
  end

  def reading_pages(paths, state) do
    debug("reading_pages/2 called")
    Result.return({paths, state + 1})
  end

  def reading_posts(paths, state) do
    debug("reading_posts/2 called")
    Result.return({paths, state + 1})
  end

  def reading_templates(paths, state) do
    debug("reading_templates/2 called")
    Result.return({paths, state + 1})
  end

  def processing_pages(files, state) do
    debug("processing_pages/2 called")
    Result.return({files, state + 1})
  end

  def processing_posts(files, state) do
    debug("processing_posts/2 called")
    Result.return({files, state + 1})
  end

  def processing_templates(files, state) do
    debug("processing_templates/2 called")
    Result.return({files, state + 1})
  end

  def processed_pages(pages, state) do
    debug("processed_pages/2 called")
    Result.return({pages, state + 1})
  end

  def processed_posts(posts, state) do
    debug("processed_posts/2 called")
    Result.return({posts, state + 1})
  end

  def processed_templates(templates, state) do
    debug("processed_templates/2 called")
    Result.return({templates, state + 1})
  end

  def generated_post_lists(post_lists, state) do
    debug("generated_post_lists/2 called")
    Result.return({post_lists, state + 1})
  end

  def generating_fragment(html_tree, _metadata, state) do
    debug("generating_fragment/3 called")
    Result.return({html_tree, state + 1})
  end

  def generated_fragment(fragment, state) do
    debug("generated_fragment/2 called")
    Result.return({fragment, state + 1})
  end

  def rendered_pages(files, state) do
    debug("rendered_pages/2 called")
    Result.return({files, state + 1})
  end

  def wrote_files(_files, state) do
    debug("wrote_files/2 called")
    Result.return(state + 1)
  end

  defp debug(msg) do
    IO.puts("\x1b[90m#{name()} #{msg}\x1b[0m")
  end
end
