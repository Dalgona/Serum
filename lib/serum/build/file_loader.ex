defmodule Serum.Build.FileLoader do
  @moduledoc false

  _moduledocp = "A module responsible for loading project files."

  alias Serum.Build.FileLoader.{Includes, Pages, Posts, Templates}
  alias Serum.Project
  alias Serum.Result

  @type result :: %{
          templates: [Serum.File.t()],
          includes: [Serum.File.t()],
          pages: [Serum.File.t()],
          posts: [Serum.File.t()]
        }

  @doc """
  Loads project files.

  Files will be read from four subdirectories:

  - `templates/`: Template files (`*.html.eex`)
  - `includes/`: Includable template files (`*.html.eex`)
  - `pages/`: Pages (`*.md`, `*.html`, `*.html.eex`)
  - `posts/`: Blog posts (`*.md`)

  The `includes/` directory and the `posts/` directory are optional. That is,
  this function won't fail even if they don't exist. The corresponding lists
  in the resulting map will be empty.
  """
  @spec load_files(Project.t()) :: Result.t(result())
  def load_files(%Project{src: src, posts_source: posts_source}) do
    with {:ok, template_files} <- Templates.load(src),
         {:ok, include_files} <- Includes.load(src),
         {:ok, page_files} <- Pages.load(src),
         {:ok, post_files} <- Posts.load(src, posts_source) do
      {:ok,
       %{
         templates: template_files,
         includes: include_files,
         pages: page_files,
         posts: post_files
       }}
    else
      {:error, _} = error -> error
    end
  end
end
