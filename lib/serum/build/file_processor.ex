defmodule Serum.Build.FileProcessor do
  alias Serum.Page
  alias Serum.Post
  alias Serum.ProjectInfo, as: Proj
  alias Serum.Result

  @spec process_files(map(), Proj.t()) :: any() # TODO
  def process_files(files, proj) do
    %{pages: page_files, posts: post_files} = files

    with :ok <- compile_templates(files),
         {:ok, pages} <- process_pages(page_files, proj),
         {:ok, posts} <- process_posts(post_files, proj) do
    else
      {:error, _} = error -> error
    end
  end

  @spec compile_templates(map()) :: Result.t()
  defp compile_templates(file_map) do
    IO.puts("Compiling templates...")
  end

  @spec process_pages([Serum.File.t()], Proj.t()) :: Result.t([Page.t()])
  defp process_pages(files, proj) do
    IO.puts("Processing page files...")
  end

  @spec process_posts([Serum.File.t()], Proj.t()) :: Result.t([Post.t()])
  defp process_posts(files, proj) do
    IO.puts("Processing post files...")
  end
end
