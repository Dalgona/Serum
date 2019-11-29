defmodule Serum.Build.FileLoader do
  @moduledoc false

  _moduledocp = "A module responsible for loading project files."

  require Serum.Result, as: Result
  alias Serum.Build.FileLoader.{Includes, Pages, Posts, Templates}

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
  @spec load_files(binary()) :: Result.t(result())
  def load_files(src) do
    Result.run do
      template_files <- Templates.load(src)
      include_files <- Includes.load(src)
      page_files <- Pages.load(src)
      post_files <- Posts.load(src)

      Result.return(%{
        templates: template_files,
        includes: include_files,
        pages: page_files,
        posts: post_files
      })
    end
  end
end
