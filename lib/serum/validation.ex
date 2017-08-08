defmodule Serum.Validation do
  @moduledoc """
  This module provides functions related to validating project JSON files.
  """

  alias ExJsonSchema.Validator
  alias ExJsonSchema.Schema

  @spec schema(schema_name :: binary) :: binary

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
  Loads JSON schemas onto `Serum.Schema` agent.
  """
  @spec load_schema() :: :ok

  def load_schema do
    ["*", "serum.json"]
    |> Enum.each(fn x ->
      sch = x |> schema |> Poison.decode! |> Schema.resolve
      Agent.update Serum.Schema, &Map.put(&1, "schema__#{x}", sch)
    end)
  end

  @doc """
  Validates the given `data` according to `schema_name` schema.
  """
  @spec validate(binary, map) :: Error.result

  def validate(schema_name, data) do
    schema =
      Agent.get(Serum.Schema, &(&1["schema__#{schema_name}"]))
      || Agent.get(Serum.Schema, &(&1["schema__*"]))
    case Validator.validate schema, data do
      :ok -> :ok
      {:error, errors} ->
        errors =
          for {message, _} <- errors do
            {:error, {message, schema_name, 0}}
          end
        {:error, {:validate_json, errors}}
    end
  end
end
