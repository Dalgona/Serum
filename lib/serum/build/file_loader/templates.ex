defmodule Serum.Build.FileLoader.Templates do
  @moduledoc false

  _moduledocp = """
  A module for loading templates from a project or a theme.
  """

  import Serum.Build.FileLoader.Common
  import Serum.IOProxy, only: [put_msg: 2]
  alias Serum.Plugin.Client, as: PluginClient
  alias Serum.Result
  alias Serum.Theme

  @doc false
  @spec load(binary()) :: Result.t([Serum.File.t()])
  def load(src) do
    put_msg(:info, "Loading template files...")

    with {:ok, theme_paths} <- Theme.get_templates(),
         {:ok, proj_paths} <- get_project_templates(src),
         merged <- Map.merge(theme_paths, proj_paths, &merge_fun/3),
         {:ok, _} <- validate_required(merged, src) do
      merged
      |> Enum.map(&elem(&1, 1))
      |> PluginClient.reading_templates()
      |> case do
        {:ok, files} -> read_files(files)
        {:error, _} = plugin_error -> plugin_error
      end
    else
      {:error, _} = error ->
        error
    end
  end

  @spec get_project_templates(binary()) :: Result.t(map())
  defp get_project_templates(src) do
    templates_dir = get_subdir(src, "templates")

    map =
      templates_dir
      |> Path.join("*.html.eex")
      |> Path.wildcard()
      |> Enum.map(&{Path.basename(&1, ".html.eex"), &1})
      |> Map.new()

    {:ok, map}
  end

  @spec merge_fun(binary(), binary(), binary()) :: binary()
  defp merge_fun(_k, from_theme, from_proj) do
    (File.exists?(from_proj) && from_proj) || from_theme
  end

  @spec validate_required(map(), binary()) :: Result.t({})
  defp validate_required(map, src) do
    existing_templates = map |> Map.keys() |> MapSet.new()

    ~w(base list page post)
    |> MapSet.new()
    |> MapSet.difference(existing_templates)
    |> MapSet.to_list()
    |> case do
      [] ->
        {:ok, {}}

      missings when is_list(missings) ->
        errors =
          Enum.map(missings, fn missing ->
            {:error, {:enoent, Path.join([src, "templates", missing]), 0}}
          end)

        {:error, {:file_loader, errors}}
    end
  end
end
