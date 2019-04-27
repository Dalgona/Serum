defmodule Serum.Build.FileLoader do
  @moduledoc "A module responsible for loading project files."

  import Serum.Util
  alias Serum.Plugin
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
  @spec load_files(binary()) :: Result.t(result())
  def load_files(src) do
    with {:ok, template_files} <- load_templates(src),
         {:ok, include_files} <- load_includes(src),
         {:ok, page_files} <- load_pages(src),
         {:ok, post_files} <- load_posts(src) do
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

  @spec load_templates(binary()) :: Result.t([Serum.File.t()])
  defp load_templates(src) do
    IO.puts("Loading template files...")

    templates_dir = get_subdir(src, "templates")

    ["base", "list", "page", "post"]
    |> Enum.map(&Path.join(templates_dir, &1 <> ".html.eex"))
    |> Plugin.reading_templates()
    |> case do
      {:ok, files} -> read_files(files)
      {:error, _} = plugin_error -> plugin_error
    end
  end

  @spec load_includes(binary()) :: Result.t([Serum.File.t()])
  defp load_includes(src) do
    IO.puts("Loading include files...")

    includes_dir = get_subdir(src, "includes")

    if File.exists?(includes_dir) do
      includes_dir
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".html.eex"))
      |> Enum.map(&Path.join(includes_dir, &1))
      |> Plugin.reading_templates()
      |> case do
        {:ok, files} -> read_files(files)
        {:error, _} = plugin_error -> plugin_error
      end
    else
      {:ok, []}
    end
  end

  @spec load_pages(binary()) :: Result.t([Serum.File.t()])
  defp load_pages(src) do
    IO.puts("Loading page files...")

    pages_dir = get_subdir(src, "pages")

    if File.exists?(pages_dir) do
      [pages_dir, "**", "*.{md,html,html.eex}"]
      |> Path.join()
      |> Path.wildcard()
      |> Plugin.reading_pages()
      |> case do
        {:ok, files} -> read_files(files)
        {:error, _} = plugin_error -> plugin_error
      end
    else
      {:error, {:enoent, pages_dir, 0}}
    end
  end

  @spec load_posts(binary()) :: Result.t([Serum.File.t()])
  defp load_posts(src) do
    IO.puts("Loading post files...")

    posts_dir = get_subdir(src, "posts")

    if File.exists?(posts_dir) do
      posts_dir
      |> Path.join("*.md")
      |> Path.wildcard()
      |> Enum.sort()
      |> Plugin.reading_posts()
      |> case do
        {:ok, files} -> read_files(files)
        {:error, _} = plugin_error -> plugin_error
      end
    else
      warn("Cannot access `posts/'. No post will be generated.")

      {:ok, []}
    end
  end

  @spec get_subdir(binary(), binary()) :: binary()
  defp get_subdir(src, subdir) do
    (src == "." && subdir) || Path.join(src, subdir)
  end

  @spec read_files([binary()]) :: Result.t([Serum.File.t()])
  defp read_files(paths) do
    paths
    |> Stream.map(&%Serum.File{src: &1})
    |> Enum.map(&Serum.File.read/1)
    |> Result.aggregate_values(:file_loader)
  end
end
