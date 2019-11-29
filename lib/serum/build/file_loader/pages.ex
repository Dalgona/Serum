defmodule Serum.Build.FileLoader.Pages do
  @moduledoc false

  _moduledocp = "A module for loading pages from a project."

  import Serum.Build.FileLoader.Common
  import Serum.IOProxy, only: [put_msg: 2]
  alias Serum.Plugin.Client, as: PluginClient
  alias Serum.Result

  @doc false
  @spec load(binary()) :: Result.t([Serum.File.t()])
  def load(src) do
    put_msg(:info, "Loading page files...")

    pages_dir = get_subdir(src, "pages")

    if File.exists?(pages_dir) do
      [pages_dir, "**", "*.{md,html,html.eex}"]
      |> Path.join()
      |> Path.wildcard()
      |> PluginClient.reading_pages()
      |> case do
        {:ok, files} -> read_files(files)
        {:error, _} = plugin_error -> plugin_error
      end
    else
      {:error, {:enoent, pages_dir, 0}}
    end
  end
end
