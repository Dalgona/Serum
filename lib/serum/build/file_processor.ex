defmodule Serum.Build.FileProcessor do
  @moduledoc "Processes the input files to produce the intermediate data."

  alias Serum.Build.FileLoader
  alias Serum.GlobalBindings
  alias Serum.Page
  alias Serum.Plugin
  alias Serum.Post
  alias Serum.PostList
  alias Serum.Project
  alias Serum.Result
  alias Serum.Tag
  alias Serum.Template
  alias Serum.Template.Compiler, as: TC

  @type tag_groups() :: [{Tag.t(), [Post.t()]}]
  @type tag_counts() :: [{Tag.t(), integer()}]

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
  @spec process_files(FileLoader.result(), Project.t()) :: Result.t(result())
  def process_files(files, proj) do
    %{pages: page_files, posts: post_files} = files

    with :ok <- compile_templates(files),
         {:ok, {pages, compact_pages}} <- process_pages(page_files, proj),
         {:ok, {posts, compact_posts}} <- process_posts(post_files, proj),
         {:ok, {lists, tag_counts}} <- generate_lists(compact_posts, proj) do
      update_global_bindings(compact_pages, compact_posts, tag_counts)

      {:ok, %{pages: pages, posts: posts, lists: lists}}
    else
      {:error, _} = error -> error
    end
  end

  @spec compile_templates(map()) :: Result.t()
  defp compile_templates(files) do
    IO.puts("Compiling templates...")

    with {:ok, includes} <- TC.compile_files(files.includes, :include),
         :ok <- Template.load(includes, :include),
         {:ok, templates} <- TC.compile_files(files.templates, :template) do
      Template.load(templates, :template)
    else
      {:error, _} = error -> error
    end
  end

  @doc false
  @spec process_pages([Serum.File.t()], Project.t()) :: Result.t({[Page.t()], [map()]})
  def process_pages(files, proj) do
    IO.puts("Processing page files...")

    files
    |> Task.async_stream(&process_page(&1, proj))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate_values(:file_processor)
    |> case do
      {:ok, pages} ->
        sorted_pages = Enum.sort(pages, &(&1.order < &2.order))

        {:ok, {sorted_pages, Enum.map(sorted_pages, &Page.compact/1)}}

      {:error, _} = error ->
        error
    end
  end

  @spec process_page(Serum.File.t(), Project.t()) :: Result.t(Page.t())
  defp process_page(file, proj) do
    import Serum.HeaderParser

    opts = [
      title: :string,
      label: :string,
      group: :string,
      order: :integer
    ]

    required = [:title]

    with {:ok, file2} <- Plugin.processing_page(file),
         {:ok, {header, rest}} <- parse_header(file2.in_data, opts, required) do
      header = Map.put(header, :label, header[:label] || header.title)
      page = Page.new(file2.src, header, rest, proj)

      Plugin.processed_page(page)
    else
      {:invalid, message} -> {:error, {message, file.src, 0}}
      {:error, _} = plugin_error -> plugin_error
    end
  end

  @doc false
  @spec process_posts([Serum.File.t()], Project.t()) :: Result.t({[Post.t()], [map()]})
  def process_posts(files, proj) do
    IO.puts("Processing post files...")

    files
    |> Task.async_stream(&process_post(&1, proj))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate_values(:file_processor)
    |> case do
      {:ok, posts} ->
        sorted_posts = Enum.sort(posts, &(&1.raw_date > &2.raw_date))

        {:ok, {sorted_posts, Enum.map(sorted_posts, &Post.compact/1)}}

      {:error, _} = error ->
        error
    end
  end

  @spec process_post(Serum.File.t(), Project.t()) :: Result.t(Post.t())
  defp process_post(file, proj) do
    import Serum.HeaderParser

    opts = [
      title: :string,
      tags: {:list, :string},
      date: :datetime
    ]

    required = [:title, :date]

    with {:ok, file2} <- Plugin.processing_post(file),
         {:ok, {header, rest}} <- parse_header(file2.in_data, opts, required) do
      header = %{
        header
        | date: header[:date] || Timex.to_datetime(Timex.zero(), :local)
      }

      post = Post.new(file2.src, header, Earmark.as_html!(rest), proj)

      Plugin.processed_post(post)
    else
      {:invalid, message} -> {:error, {message, file.src, 0}}
      {:error, _} = plugin_error -> plugin_error
    end
  end

  @doc false
  @spec generate_lists([map()], Project.t()) :: Result.t({[PostList.t()], tag_counts()})
  def generate_lists(compact_posts, proj) do
    IO.puts("Generating post lists...")

    tag_groups = group_posts_by_tag(compact_posts)

    [{nil, compact_posts} | tag_groups]
    |> Task.async_stream(fn {tag, posts} ->
      PostList.generate(tag, posts, proj)
    end)
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate_values(:file_processor)
    |> case do
      {:ok, lists} -> {:ok, {List.flatten(lists), get_tag_counts(tag_groups)}}
      {:error, _} = error -> error
    end
  end

  @spec group_posts_by_tag([map()], map()) :: tag_groups()
  defp group_posts_by_tag(posts, acc \\ %{})

  defp group_posts_by_tag([], acc) do
    Enum.map(acc, fn {tag, posts} -> {tag, Enum.reverse(posts)} end)
  end

  defp group_posts_by_tag([post | posts], acc1) do
    new_acc =
      Enum.reduce(post.tags, acc1, fn tag, acc2 ->
        acc2
        |> Map.get_and_update(tag, fn
          nil -> {nil, [post]}
          posts when is_list(posts) -> {posts, [post | posts]}
        end)
        |> elem(1)
      end)

    group_posts_by_tag(posts, new_acc)
  end

  @spec get_tag_counts(tag_groups()) :: tag_counts()
  defp get_tag_counts(tags) do
    Enum.map(tags, fn {k, v} -> {k, Enum.count(v)} end)
  end

  @spec update_global_bindings([map()], [map()], tag_counts()) :: :ok
  def update_global_bindings(compact_pages, compact_posts, tag_counts) do
    GlobalBindings.put(:all_pages, compact_pages)
    GlobalBindings.put(:all_posts, compact_posts)
    GlobalBindings.put(:all_tags, tag_counts)
  end
end
