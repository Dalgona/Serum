defmodule Serum.Validation do
  @moduledoc """
  This module provides functions related to validating project JSON files.
  """

  alias ExJsonSchema.Validator

  defp schema("*") do
    "{}"
  end

  defp schema("serum.json") do """
    {
      "type": "object",
      "properties": {
        "site_name": { "type": "string" },
        "site_description": { "type": "string" },
        "author": { "type": "string" },
        "author_email": { "type": "string" },
        "base_url": {
          "type": "string",
          "pattern": ".*/$"
        },
        "date_format": { "type": "string" },
        "preview_length": {
          "type": "integer",
          "minimum": 0
        }
      },
      "additionalProperties": false,
      "required": [
        "site_name", "site_description",
        "author", "author_email",
        "base_url"
      ]
    }
  """ end

  @doc """
  Loads JSON schemas onto `Serum.BuildData` agent once.
  """
  @spec load_schema() :: :ok
  def load_schema do
    ["*", "serum.json"]
    |> Enum.filter(fn x -> Serum.get_data("schema", x) == nil end)
    |> Enum.each(fn x ->
      sch =
        x
        |> schema
        |> Poison.decode!
        |> ExJsonSchema.Schema.resolve
      Serum.put_data("schema", x, sch)
    end)
  end

  @doc """
  Validates the given `data` according to `schema_name` schema.
  """
  @spec validate(String.t, map) :: :ok | {:error, Validator.errors}
  def validate(schema_name, data) do
    schema =
      Serum.get_data("schema", schema_name)
      || Serum.get_data("schema", "*")
    Validator.validate(schema, data)
  end

  @doc """
  Same as `validate/2`, but a `Serum.ValidationError` exception will be raised
  when `data` as invalid.
  """
  @spec validate!(String.t, map) :: :ok
  @raises [Serum.ValidationError]
  def validate!(schema_name, data) do
    case validate(schema_name, data) do
      :ok -> :ok
      {:error, e} ->
        raise Serum.ValidationError, schema: schema_name, errors: e
    end
  end
end

