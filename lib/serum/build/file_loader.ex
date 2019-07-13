defmodule Serum.Build.FileLoader do
  @moduledoc false

  _moduledocp = "A module responsible for loading project files."

  import Serum.IOProxy, only: [put_err: 2, put_msg: 2]
  alias Serum.Plugin
  alias Serum.Result
  alias Serum.Theme

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
    put_msg(:info, "Loading template files...")

    case Theme.get_templates() do
      {:ok, paths} ->
        paths
        |> Map.merge(get_project_templates(src), fn _, v1, v2 ->
          (File.exists?(v2) && v2) || v1
        end)
        |> Enum.map(&elem(&1, 1))
        |> Plugin.reading_templates()
        |> case do
          {:ok, files} -> read_files(files)
          {:error, _} = plugin_error -> plugin_error
        end

      {:error, _} = error ->
        error
    end
  end

  @spec get_project_templates(binary()) :: map()
  defp get_project_templates(src) do
    templates_dir = get_subdir(src, "templates")

    ["base", "list", "page", "post"]
    |> Enum.map(&{&1, Path.join(templates_dir, &1 <> ".html.eex")})
    |> Map.new()
  end

  @spec load_includes(binary()) :: Result.t([Serum.File.t()])
  defp load_includes(src) do
    put_msg(:info, "Loading include files...")

    case Theme.get_includes() do
      {:ok, paths} ->
        paths
        |> Map.merge(get_project_includes(src))
        |> Enum.map(&elem(&1, 1))
        |> Plugin.reading_templates()
        |> case do
          {:ok, files} -> read_files(files)
          {:error, _} = plugin_error -> plugin_error
        end

      {:error, _} = error ->
        error
    end
  end

  @spec get_project_includes(binary()) :: map()
  defp get_project_includes(src) do
    includes_dir = get_subdir(src, "includes")

    if File.exists?(includes_dir) do
      includes_dir
      |> File.ls!()
      |> Enum.filter(&String.ends_with?(&1, ".html.eex"))
      |> Enum.map(&Path.join(includes_dir, &1))
      |> Enum.map(&{Path.basename(&1, ".html.eex"), &1})
      |> Map.new()
    else
      %{}
    end
  end

  @spec load_pages(binary()) :: Result.t([Serum.File.t()])
  defp load_pages(src) do
    put_msg(:info, "Loading page files...")

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
    put_msg(:info, "Loading post files...")

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
      put_err(:warn, "Cannot access `posts/'. No post will be generated.")

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
