defmodule Serum.Build.FileLoader.Templates do
  @moduledoc false

  _moduledocp = """
  A module for loading templates from a project or a theme.
  """

  require Serum.V2.Result, as: Result
  import Serum.Build.FileLoader.Common
  import Serum.V2.Console, only: [put_msg: 2]
  alias Serum.Plugin.Client, as: PluginClient
  alias Serum.Theme.Client, as: ThemeClient
  alias Serum.V2
  alias Serum.V2.Error

  @doc false
  @spec load(binary()) :: Result.t([V2.File.t()])
  def load(src) do
    put_msg(:info, "Loading template files...")

    Result.run do
      theme_paths <- ThemeClient.get_templates()
      proj_paths <- get_project_templates(src)
      merged = Map.merge(theme_paths, proj_paths, &merge_fun/3)
      validate_required(merged, src)

      merged
      |> Enum.map(&elem(&1, 1))
      |> PluginClient.reading_templates()
      |> case do
        {:ok, files} -> read_files(files)
        {:error, %Error{}} = plugin_error -> plugin_error
      end
    end
  end

  @spec get_project_templates(binary()) :: Result.t(map())
  defp get_project_templates(src) do
    Result.return do
      src
      |> get_subdir("templates")
      |> Path.join("*.html.eex")
      |> Path.wildcard()
      |> Enum.map(&{Path.basename(&1, ".html.eex"), &1})
      |> Map.new()
    end
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
        Result.return()

      missings when is_list(missings) ->
        errors =
          Enum.map(missings, fn missing ->
            file = %V2.File{src: Path.join([src, "templates", missing])}

            Result.fail(POSIX, :enoent, file: file)
          end)

        Result.aggregate(errors, "some required templates are missing:")
    end
  end
end
