defmodule Serum.Build.FileProcessor do
  @moduledoc "Processes the input files to produce the intermediate data."

  alias Serum.Build.FileLoader
  alias Serum.GlobalBindings
  alias Serum.Page
  alias Serum.Post
  alias Serum.PostList
  alias Serum.Project
  alias Serum.Result
  alias Serum.Tag
  alias Serum.Template.Compiler, as: TC

  @type result() :: %{
          pages: [Page.t()],
          posts: [Post.t()],
          lists: [PostList.t()],
          templates: map(),
          includes: map()
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
  @spec process_files(FileLoader.result(), Project.t()) :: Result.t(result())
  def process_files(files, proj) do
    import Serum.Build.FileProcessor.{Page, Post, PostList}

    %{pages: page_files, posts: post_files} = files

    with {:ok, {templates, includes}} <- compile_templates(files),
         {:ok, {pages, compact_pages}} <- preprocess_pages(page_files, proj),
         {:ok, {posts, compact_posts}} <- process_posts(post_files, proj),
         {:ok, {lists, tag_counts}} <- generate_lists(compact_posts, proj),
         update_global_bindings(compact_pages, compact_posts, tag_counts),
         {:ok, pages} <- process_pages(pages, includes, proj) do
      result = %{
        pages: pages,
        posts: posts,
        lists: lists,
        templates: templates,
        includes: includes
      }

      {:ok, result}
    else
      {:error, _} = error -> error
    end
  end

  @spec compile_templates(map()) :: Result.t({map(), map()})
  defp compile_templates(%{templates: templates, includes: includes}) do
    IO.puts("Compiling templates...")

    with {:ok, includes} <- TC.compile_files(includes, type: :include),
         tc_options = [type: :template, includes: includes],
         {:ok, templates} <- TC.compile_files(templates, tc_options) do
      {:ok, {templates, includes}}
    else
      {:error, _} = error -> error
    end
  end

  @spec update_global_bindings([map()], [map()], [{Tag.t(), integer()}]) :: :ok
  def update_global_bindings(compact_pages, compact_posts, tag_counts) do
    GlobalBindings.put(:all_pages, compact_pages)
    GlobalBindings.put(:all_posts, compact_posts)
    GlobalBindings.put(:all_tags, tag_counts)
  end
end
