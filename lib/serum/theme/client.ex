defmodule Serum.Theme.Client do
  @moduledoc false

  _moduledocp = "Defines functions for calling functions of a loaded theme."

  require Serum.ForeignCode, as: ForeignCode
  require Serum.V2.Result, as: Result
  alias Serum.Theme
  alias Serum.V2

  @type path_map :: %{optional(binary()) => binary()}

  @spec get_includes() :: Result.t(path_map())
  def get_includes do
    Result.run do
      paths <- call_function(:get_includes, [], [])
      check_list_type(paths, :get_includes)

      paths |> make_path_map() |> Result.return()
    end
  end

  @spec get_templates() :: Result.t(path_map())
  def get_templates do
    Result.run do
      paths <- call_function(:get_templates, [], [])
      check_list_type(paths, :get_templates)

      paths |> make_path_map() |> Result.return()
    end
  end

  @spec get_assets() :: Result.t(binary() | false)
  def get_assets do
    Result.run do
      path <- call_function(:get_assets, [], false)

      handle_assets_dir(path)
    end
  end

  @spec call_function(atom(), list(), term()) :: Result.t(term())
  defp call_function(fun, args, default) do
    case Agent.get(Theme, & &1) do
      {nil, _} ->
        Result.return(default)

      {%Theme{module: module}, state} ->
        new_args = args ++ [state]

        ForeignCode.call apply(module, fun, new_args) do
          value -> Result.return(value)
        end
    end
  end

  @spec check_list_type(term(), String.Chars.t()) :: Result.t({})
  defp check_list_type(maybe_list, fun_name)
  defp check_list_type([], _fun_name), do: Result.return()

  defp check_list_type([x | xs], fun_name) when is_binary(x) do
    check_list_type(xs, fun_name)
  end

  defp check_list_type([x | _xs], fun_name) do
    Result.fail(
      "theme: expected #{fun_name} to return a list of strings, " <>
        "but #{inspect(x)} was in the list"
    )
  end

  defp check_list_type(x, fun_name) do
    Result.fail(
      "theme: expected #{fun_name} to return a list of strings, " <>
        "got: #{inspect(x)} in the list"
    )
  end

  @spec handle_assets_dir(term()) :: Result.t(binary() | false)
  defp handle_assets_dir(value)
  defp handle_assets_dir(path) when is_binary(path), do: validate_assets_dir(path)
  defp handle_assets_dir(false), do: Result.return(false)

  defp handle_assets_dir(x) do
    Result.fail("theme: expected get_assets to return a string, got: #{inspect(x)}")
  end

  @spec validate_assets_dir(binary()) :: Result.t(binary())
  defp validate_assets_dir(path) do
    case File.stat(path) do
      {:ok, %File.Stat{type: :directory}} -> Result.return(path)
      {:ok, %File.Stat{}} -> Result.fail(POSIX, :enotdir, file: %V2.File{src: path})
      {:error, reason} -> Result.fail(POSIX, reason, file: %V2.File{src: path})
    end
  end

  @spec make_path_map([binary()]) :: %{optional(binary()) => binary()}
  defp make_path_map(paths) do
    paths
    |> Enum.filter(&String.ends_with?(&1, ".html.eex"))
    |> Enum.map(&{Path.basename(&1, ".html.eex"), &1})
    |> Map.new()
  end
end
