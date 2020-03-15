defmodule Serum.HeaderParser do
  @moduledoc false

  _moduledocp = """
  This module takes care of parsing headers of page (or post) source files.

  Header is where all page or post metadata goes into, and has the following
  format:

  ```
  ---
  key: value
  ...
  ---
  ```

  where `---` in the first and last line delimits the beginning and the end of
  the header area, and between these two lines are one or more key-value pair
  delimited by a colon, where key is the name of a metadata and value is the
  actual value of a metadata.
  """

  require Serum.V2.Result, as: Result
  alias Serum.HeaderParser.Extract
  alias Serum.HeaderParser.ValueTransformer
  alias Serum.V2
  alias Serum.V2.Error

  @type options :: [{atom(), value_type()}]
  @type value_type :: :string | :integer | :datetime | {:list, value_type()}
  @type value :: binary() | integer() | DateTime.t() | [binary()] | [integer()] | [DateTime.t()]
  @typep parse_result :: Result.t({map(), map(), binary(), integer()})

  @doc """
  Reads lines from a binary `data` and extracts the header into a map.

  `options` is a keyword list which specifies the name and type of metadata the
  header parser expects. So the typical `options` should look like this:

      [key1: type1, key2: type2, ...]

  See "Types" section for avilable value types.

  `required` argument is a list of required keys (in atom). If the header parser
  cannot find required keys in the header area, it returns an error.

  ## Types

  Currently the HeaderParser supports following types:

  * `:string` - A line of string. It can contain spaces.
  * `:integer` - A decimal integer.
  * `:datetime` - Date and time. Must be specified in the format of
    `YYYY-MM-DD hh:mm:ss`. This data will be interpreted as a local time.
  * `{:list, <type>}` - A list of multiple values separated by commas. Every
    value must have the same type, either `:string`, `:integer`, or `:datetime`.
    You cannot make a list of lists.
  """
  @spec parse_header(V2.File.t(), options(), [atom()]) :: parse_result()
  def parse_header(file, options, required \\ [])

  def parse_header(%V2.File{in_data: nil} = file, _, _) do
    Result.fail(Simple: ["cannot parse header: the file is not loaded"], file: file)
  end

  def parse_header(file, options, required) do
    Result.run do
      {kvs, rest, next_line} <- Extract.extract_header(file.in_data)

      key_strings = options |> Keyword.keys() |> Enum.map(&to_string/1)
      kv_groups = Enum.group_by(kvs, &(elem(elem(&1, 0), 0) in key_strings))
      accepted_kv = kv_groups[true] || []
      extras = kv_groups |> Map.get(false, []) |> Enum.map(&elem(&1, 0))

      find_missing(accepted_kv, required, next_line)
      parsed <- transform_values(accepted_kv, options)

      Result.return({Map.new(parsed), Map.new(extras), rest, next_line})
    end
    |> case do
      {:ok, _} = result ->
        result

      {:error, %Error{} = error} ->
        {:error, Error.prewalk(error, &%Error{&1 | file: file})}
    end
  end

  @spec find_missing([{binary(), binary()}], [atom()], integer()) :: Result.t({})
  defp find_missing(kv_list, required, line) do
    req_strings = required |> Enum.map(&to_string/1) |> MapSet.new()
    keys = kv_list |> Enum.map(&elem(elem(&1, 0), 0)) |> MapSet.new()

    req_strings
    |> MapSet.difference(keys)
    |> MapSet.to_list()
    |> case do
      [] -> Result.return()
      missings -> Result.fail(Simple: [missing_message(missings)], line: line - 1)
    end
  end

  @spec missing_message([binary()]) :: binary()
  defp missing_message(missings)
  defp missing_message([missing]), do: "`#{missing}` is required, but missing"

  defp missing_message(missings) do
    repr = missings |> Enum.map(&"`#{&1}`") |> Enum.reverse() |> Enum.join(", ")

    "#{repr} are required, but missing"
  end

  @spec transform_values([{{binary(), binary()}, integer()}], keyword(atom())) ::
          Result.t([{atom(), value()}])
  defp transform_values(kvs, options) do
    kvs
    |> Enum.map(fn {{key, _value} = kv, line} ->
      atom_key = String.to_existing_atom(key)

      case ValueTransformer.transform_value(kv, options[atom_key], line) do
        {:ok, value} -> Result.return({atom_key, value})
        {:error, %Error{}} = error -> error
      end
    end)
    |> Result.aggregate("failed to parse the header:")
  end
end
