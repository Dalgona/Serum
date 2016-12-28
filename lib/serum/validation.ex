defmodule Serum.Validation do
  @moduledoc """
  This module provides functions related to validating project JSON files.
  """

  alias ExJsonSchema.Validator
  alias ExJsonSchema.Schema

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
        "base_url": { "type": "string", "pattern": ".*/$" },
        "date_format": { "type": "string" },
        "preview_length": { "type": "integer", "minimum": 0 },
        "list_title_all": { "type": "string" },
        "list_title_tag": { "type": "string" }
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
      sch = x |> schema |> Poison.decode! |> Schema.resolve
      Serum.put_data("schema", x, sch)
    end)
  end

  @doc """
  Validates the given `data` according to `schema_name` schema.
  """
  @spec validate(String.t, map) :: Error.result
  def validate(schema_name, data) do
    schema =
      Serum.get_data("schema", schema_name) || Serum.get_data("schema", "*")
    case Validator.validate schema, data do
      :ok -> :ok
      {:error, errors} ->
        errors =
          for {message, _} <- errors do
            {:error, :validation_error, {message, schema_name, 0}}
          end
        {:error, :child_task, {:validate_json, errors}}
    end
  end
end
