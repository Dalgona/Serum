defmodule Serum.ProjectLoader do
  @moduledoc false

  alias Serum.GlobalBindings
  alias Serum.Project
  alias Serum.Result
  alias Serum.Validation

  @spec load(binary(), binary()) :: Result.t(Project.t())
  def load(src, dest) do
    cond do
      File.exists?(Path.join(src, "serum.exs")) -> load_exs(src, dest)
      File.exists?(Path.join(src, "serum.json")) -> load_json(src, dest)
      :else -> {:error, {:enoent, Path.join(src, "serum.exs"), 0}}
    end
  end

  @spec load_json(binary(), binary()) :: Result.t(Project.t())
  defp load_json(src, dest) do
    path = Path.join(src, "serum.json")

    with {:ok, data} <- File.read(path),
         {:ok, json} <- Poison.decode(data),
         :ok <- Validation.validate("project_info", json, path) do
      proj =
        json
        |> Enum.map(fn {k, v} -> {String.to_atom(k), v} end)
        |> Map.new()
        |> Project.new()

      GlobalBindings.put(:site, %{
        name: proj.site_name,
        description: proj.site_description,
        author: proj.author,
        author_email: proj.author_email,
        server_root: proj.server_root,
        base_url: proj.base_url
      })

      {:ok, %Project{proj | src: src, dest: dest}}
    else
      # From File.read/1:
      {:error, reason} when is_atom(reason) ->
        {:error, {reason, path, 0}}

      # From Poison.decode/1:
      {:error, :invalid, pos} ->
        {:error, {"parse error at position #{pos}", path, 0}}

      {:error, {:invalid, token, pos}} ->
        {:error, {"parse error near `#{token}' at position #{pos}", path, 0}}

      # From Validation.validate/3:
      {:error, _} = error ->
        error
    end
  end

  @spec load_exs(binary(), binary()) :: Result.t(Project.t())
  defp load_exs(src, dest) do
  end
end
