defmodule Serum.Project.JsonValidator do
  @moduledoc """
  This module provides functions related to validating project JSON files.

  ## Note

  JSON format of Serum project definition is deprecated in favor of the
  Elixir-based format.
  """

  alias ExJsonSchema.Schema
  alias ExJsonSchema.Validator
  alias Serum.Result

  @spec schema(schema_name :: binary) :: map

  schema_files =
    :serum
    |> :code.priv_dir()
    |> Path.join("build_resources/json_schema/*.json")
    |> Path.wildcard()

  for path <- schema_files do
    basename = Path.basename(path, ".json")

    schema_data =
      path
      |> File.read!()
      |> Poison.decode!()
      |> Schema.resolve()

    def schema(unquote(basename)) do
      unquote(Macro.escape(schema_data))
    end
  end

  @doc """
  Validates the given `data` according to `schema_name` schema.
  """
  @spec validate(binary, map, binary) :: Result.t()

  def validate(schema_name, data, path) do
    schema = schema(schema_name)

    case Validator.validate(schema, data) do
      :ok ->
        :ok

      {:error, errors} ->
        errors =
          for {message, element} <- errors do
            {:error, {message <> " (#{element})", path, 0}}
          end

        {:error, {:validate_json, errors}}
    end
  end
end
