defmodule Serum.Build.FileLoader.Templates do
  @moduledoc false

  _moduledocp = """
  A module for loading templates from a project or a theme.
  """

  import Serum.Build.FileLoader.Common
  import Serum.IOProxy, only: [put_msg: 2]
  alias Serum.Plugin
  alias Serum.Result
  alias Serum.Theme

  @doc false
  @spec load(binary()) :: Result.t([Serum.File.t()])
  def load(src) do
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
end
