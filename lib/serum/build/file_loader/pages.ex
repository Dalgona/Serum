defmodule Serum.Build.FileLoader.Pages do
  @moduledoc false

  _moduledocp = "A module for loading pages from a project."

  require Serum.V2.Result, as: Result
  import Serum.Build.FileLoader.Common
  import Serum.V2.Console, only: [put_msg: 2]
  alias Serum.Plugin.Client, as: PluginClient
  alias Serum.V2

  @doc false
  @spec load(binary()) :: Result.t([V2.File.t()])
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
      Result.fail(POSIX, :enoent, file: %V2.File{src: pages_dir})
    end
  end
end
