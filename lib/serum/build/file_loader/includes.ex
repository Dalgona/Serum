defmodule Serum.Build.FileLoader.Includes do
  @moduledoc false

  _moduledocp = """
  A module for loading includes from a project or a theme.
  """

  import Serum.Build.FileLoader.Common
  import Serum.IOProxy, only: [put_msg: 2]
  alias Serum.Plugin
  alias Serum.Result
  alias Serum.Theme

  @doc false
  @spec load(binary()) :: Result.t([Serum.File.t()])
  def load(src) do
    put_msg(:info, "Loading includes...")

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
      |> Path.join("*.html.eex")
      |> Path.wildcard()
      |> Enum.map(&{Path.basename(&1, ".html.eex"), &1})
      |> Map.new()
    else
      %{}
    end
  end
end
