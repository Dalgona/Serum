defmodule Serum.Build.FileProcessor do
  alias Serum.Page
  alias Serum.Post
  alias Serum.ProjectInfo, as: Proj
  alias Serum.Result
  alias Serum.Template
  alias Serum.TemplateCompiler, as: TC

  @spec process_files(map(), Proj.t()) :: any() # TODO
  def process_files(files, proj) do
    %{pages: page_files, posts: post_files} = files

    with :ok <- compile_templates(files),
         page_task = Task.async(fn -> process_pages(page_files, proj) end),
         post_task = Task.async(fn -> process_posts(post_files, proj) end),
         {:ok, pages} <- Task.await(page_task),
         {:ok, posts} <- Task.await(post_task) do
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

  @spec process_pages([Serum.File.t()], Proj.t()) :: Result.t([Page.t()])
  defp process_pages(files, proj) do
    IO.puts("Processing page files...")

    files
    |> Task.async_stream(Page, :load, [proj])
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate_values(:file_processor)
  end

  @spec process_posts([Serum.File.t()], Proj.t()) :: Result.t([Post.t()])
  defp process_posts(files, proj) do
    IO.puts("Processing post files...")

    files
    |> Task.async_stream(&process_post(&1, proj))
    |> Enum.map(&elem(&1, 1))
    |> Result.aggregate_values(:file_processor)
  end

  @spec process_post(Serum.File.t(), Proj.t()) :: Result.t(Post.t())
  defp process_post(file, proj) do
    alias Serum.HeaderParser

    opts = [
      title: :string,
      tags: {:list, :string},
      date: :datetime
    ]

    required = [:title]

    case HeaderParser.parse_header(file, opts, required) do
      {:ok, header, rest_data} ->
        header = %{
          header
          | date: header[:date] || Timex.to_datetime(Timex.zero(), :local)
        }

        {:ok, Post.new(file.src, header, Earmark.as_html!(rest_data), proj)}

      {:error, _} = error ->
        error
    end
  end
end
