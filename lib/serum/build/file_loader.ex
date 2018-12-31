defmodule Serum.Build.FileLoader do
  @moduledoc false

  import Serum.Util
  alias Serum.ProjectInfo
  alias Serum.Result

  @spec load_files(ProjectInfo.t()) :: Result.t(map())
  def load_files(%ProjectInfo{src: src}) do
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
    |> read_files()
  end

  @spec load_includes(binary()) :: Result.t([Serum.File.t()])
  defp load_includes(src) do
    IO.puts("Loading include files...")

    includes_dir = get_subdir(src, "includes")

    if File.exists?(includes_dir) do
      includes_dir
      |> File.ls!()
      |> Stream.filter(&String.ends_with?(&1, ".html.eex"))
      |> Stream.map(&Path.join(includes_dir, &1))
      |> read_files()
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
      |> read_files()
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
      |> read_files()
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
