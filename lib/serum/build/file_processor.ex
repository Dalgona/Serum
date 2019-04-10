defmodule Serum.Build.FileProcessor do
  @moduledoc """
  Processes/parses the input files to produce the intermediate data.
  """

  alias Serum.GlobalBindings
  alias Serum.Page
  alias Serum.Post
  alias Serum.PostList
  alias Serum.Project
  alias Serum.Result
  alias Serum.Template
  alias Serum.Template.Compiler, as: TC

  @type tag_map() :: %{optional(Tag.t()) => [Post.t()]}

  @type result() :: %{
          pages: [Page.t()],
          posts: [Post.t()],
          lists: [[PostList.t()]]
        }

  @spec process_files(map(), Project.t()) :: Result.t(result())
  def process_files(files, proj) do
    %{pages: page_files, posts: post_files} = files

    with :ok <- compile_templates(files),
         page_task = Task.async(fn -> process_pages(page_files, proj) end),
         post_task = Task.async(fn -> process_posts(post_files, proj) end),
         {:ok, pages} <- Task.await(page_task),
         {:ok, posts} <- Task.await(post_task),
         tag_map = get_tag_map(posts),
         tag_counts = get_tag_counts(tag_map),
         lists = generate_lists(posts, tag_map, proj) do
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
    alias Serum.HeaderParser

    opts = [
      title: :string,
      label: :string,
      group: :string,
      order: :integer
    ]

    required = [:title]

    case HeaderParser.parse_header(file.in_data, opts, required) do
      {:ok, {header, rest_data}} ->
        header = Map.put(header, :label, header[:label] || header.title)

        {:ok, Page.new(file.src, header, rest_data, proj)}

      {:invalid, message} ->
        {:error, {message, file.src, 0}}
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
    alias Serum.HeaderParser

    opts = [
      title: :string,
      tags: {:list, :string},
      date: :datetime
    ]

    required = [:title]

    case HeaderParser.parse_header(file.in_data, opts, required) do
      {:ok, {header, rest_data}} ->
        header = %{
          header
          | date: header[:date] || Timex.to_datetime(Timex.zero(), :local)
        }

        {:ok, Post.new(file.src, header, Earmark.as_html!(rest_data), proj)}

      {:invalid, message} ->
        {:error, {message, file.src, 0}}
    end
  end

  @spec generate_lists([Post.t()], tag_map(), Project.t()) :: [[PostList.t()]]
  def generate_lists(posts, tag_map, proj) do
    IO.puts("Generating post lists...")

    all_posts = PostList.generate(nil, posts, proj)

    tag_lists =
      tag_map
      |> Task.async_stream(fn {tag, posts} ->
        PostList.generate(tag, posts, proj)
      end)
      |> Enum.map(&elem(&1, 1))

    [all_posts | tag_lists]
  end

  @spec get_tag_map([Post.t()]) :: map()
  defp get_tag_map(all_posts) do
    all_tags =
      Enum.reduce(all_posts, MapSet.new(), fn info, acc ->
        MapSet.union(acc, MapSet.new(info.tags))
      end)

    for tag <- all_tags, into: %{} do
      posts = Enum.filter(all_posts, &(tag in &1.tags))
      {tag, posts}
    end
  end

  @spec get_tag_counts(tag_map()) :: [{Tag.t(), integer()}]
  defp get_tag_counts(tag_map) do
    Enum.map(tag_map, fn {k, v} -> {k, Enum.count(v)} end)
  end
end
