defmodule Serum.Build.FileLoader.Posts do
  @moduledoc false

  _moduledocp = "A module for loading posts from a project."

  require Serum.Result, as: Result
  import Serum.Build.FileLoader.Common
  import Serum.V2.Console
  alias Serum.Plugin.Client, as: PluginClient
  alias Serum.V2

  @doc false
  @spec load(binary()) :: Result.t([V2.File.t()])
  def load(src) do
    put_msg(:info, "Loading post files...")

    posts_dir = get_subdir(src, "posts")

    if File.exists?(posts_dir) do
      posts_dir
      |> Path.join("*.md")
      |> Path.wildcard()
      |> Enum.sort()
      |> PluginClient.reading_posts()
      |> case do
        {:ok, files} -> read_files(files)
        {:error, _} = plugin_error -> plugin_error
      end
    else
      put_err(:warn, "Cannot access `posts/'. No post will be generated.")

      Result.return([])
    end
  end
end
