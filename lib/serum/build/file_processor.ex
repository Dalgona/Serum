defmodule Serum.Build.FileProcessor do
  @moduledoc false

  _moduledocp = "Processes the input files to produce the intermediate data."

  require Serum.V2.Result, as: Result
  alias Serum.Build.FileLoader
  alias Serum.GlobalBindings
  alias Serum.V2.BuildContext
  alias Serum.V2.Page
  alias Serum.V2.Post
  alias Serum.V2.PostList
  alias Serum.V2.Tag

  @type result() :: %{
          pages: [Page.t()],
          posts: [Post.t()],
          lists: [PostList.t()]
        }

  @doc """
  Processes the input files.

  ## Procedure

  - Compiles includable templates.
  - Compiles regular templates. Any call to the `include/1` macro in a template
    will be expanded into the corresponding includable template by the
    `Serum.Template.Compiler` module.
  - Processes page files.
  - Processes blog post files.
  - Generates post lists using information generated just before. A list of
    tags and their use counts is also created.
  - Updates the `Serum.GlobalBindings` agent so that the above information is
    available later, when rendering pages into fragments or full HTML pages.
  """
  @spec process_files(FileLoader.result(), BuildContext.t()) :: Result.t(result())
  def process_files(files, context) do
    import Serum.Build.FileProcessor.{Page, Post, PostList, Template}

    %{pages: page_files, posts: post_files} = files

    Result.run do
      compile_templates(files)
      preprocessed_pages <- preprocess_pages(page_files, context)
      {posts, compact_posts} <- preprocess_posts(post_files, context)
      {lists, tag_counts} <- generate_lists(compact_posts, context)
      update_global_bindings(preprocessed_pages, compact_posts, tag_counts)
      pages <- process_pages(preprocessed_pages, context)
      posts <- process_posts(posts, context)

      Result.return(%{
        pages: pages,
        posts: posts,
        lists: lists
      })
    end
  end

  @spec update_global_bindings([Page.t()], [map()], [{Tag.t(), integer()}]) :: Result.t({})
  def update_global_bindings(pages, compact_posts, tag_counts) do
    GlobalBindings.put(:all_pages, pages)
    GlobalBindings.put(:all_posts, compact_posts)
    GlobalBindings.put(:all_tags, tag_counts)
    Result.return()
  end
end
