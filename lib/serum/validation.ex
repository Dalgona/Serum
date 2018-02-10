defmodule Serum.Validation do
  @moduledoc """
  This module provides functions related to validating project JSON files.
  """

  alias ExJsonSchema.Validator
  alias ExJsonSchema.Schema
  alias Serum.Result

  @spec schema(schema_name :: binary) :: map

  schema_files =
    :serum
    |> :code.priv_dir()
    |> Path.join("json_schema/*.json")
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
  @spec validate(binary, map) :: Result.t()

  def validate(schema_name, data) do
    schema = schema(schema_name)

    case Validator.validate(schema, data) do
      :ok ->
        :ok

      {:error, errors} ->
        errors =
          for {message, _} <- errors do
            {:error, {message, schema_name, 0}}
          end

        {:error, {:validate_json, errors}}
    end
  end
end
