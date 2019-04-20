defmodule Serum.Build.FileProcessor do
  @moduledoc """
  Processes/parses the input files to produce the intermediate data.
  """

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

  @type tag_group() :: [{Tag.t(), [Post.t()]}]

  @type result() :: %{
          pages: [Page.t()],
          posts: [Post.t()],
          lists: [PostList.t()]
        }

  @spec process_files(map(), Project.t()) :: Result.t(result())
  def process_files(files, proj) do
    %{pages: page_files, posts: post_files} = files

    with :ok <- compile_templates(files),
         page_task = Task.async(fn -> process_pages(page_files, proj) end),
         post_task = Task.async(fn -> process_posts(post_files, proj) end),
         {:ok, pages} <- Task.await(page_task),
         {:ok, posts} <- Task.await(post_task),
         tags = group_posts_by_tag(posts),
         tag_counts = get_tag_counts(tags),
         {:ok, lists} <- generate_lists(posts, tags, proj) do
      GlobalBindings.put(:all_pages, pages)
      GlobalBindings.put(:all_posts, posts)
      GlobalBindings.put(:all_tags, tag_counts)

      result = %{pages: pages, posts: posts, lists: lists}

      {:ok, result}
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

  @spec process_pages([Serum.File.t()], Project.t()) :: Result.t([Page.t()])
  defp process_pages(files, proj) do
    IO.puts("Processing page files...")

    files
    |> Task.async_stream(&process_page(&1, proj))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate_values(:file_processor)
    |> case do
      {:ok, pages} -> {:ok, Enum.sort(pages, &(&1.order < &2.order))}
      {:error, _} = error -> error
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

  @spec process_posts([Serum.File.t()], Project.t()) :: Result.t([Post.t()])
  defp process_posts(files, proj) do
    IO.puts("Processing post files...")

    files
    |> Task.async_stream(&process_post(&1, proj))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate_values(:file_processor)
    |> case do
      {:ok, posts} -> {:ok, Enum.sort(posts, &(&1.raw_date > &2.raw_date))}
      {:error, _} = error -> error
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

    required = [:title]

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

  @spec generate_lists([Post.t()], tag_group(), Project.t()) :: Result.t([PostList.t()])
  defp generate_lists(posts, tags, proj) do
    IO.puts("Generating post lists...")

    [{nil, posts} | tags]
    |> Task.async_stream(fn {tag, posts} ->
      PostList.generate(tag, posts, proj)
    end)
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate_values(:file_processor)
    |> case do
      {:ok, lists} -> {:ok, List.flatten(lists)}
      {:error, _} = error -> error
    end
  end

  @spec group_posts_by_tag([Post.t()]) :: tag_group()
  defp group_posts_by_tag(all_posts) do
    all_tags =
      Enum.reduce(all_posts, MapSet.new(), fn post, acc ->
        MapSet.union(acc, MapSet.new(post.tags))
      end)

    all_tags
    |> Task.async_stream(fn tag ->
      posts = Enum.filter(all_posts, &(tag in &1.tags))

      {tag, posts}
    end)
    |> Enum.map(&elem(&1, 1))
  end

  @spec get_tag_counts(tag_group()) :: [{Tag.t(), integer()}]
  defp get_tag_counts(tags) do
    Enum.map(tags, fn {k, v} -> {k, Enum.count(v)} end)
  end
end
