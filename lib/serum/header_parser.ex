defmodule Serum.HeaderParser do
  @moduledoc """
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

  @date_format1 "{YYYY}-{0M}-{0D} {h24}:{m}:{s}"
  @date_format2 "{YYYY}-{0M}-{0D}"

  @type options :: [{atom, value_type}]
  @type value_type :: :string | :integer | :datetime | {:list, value_type}
  @type value :: binary | integer | [binary] | [integer]
  @type parse_result :: {:ok, {map(), binary()}} | {:invalid, binary()}

  @typep extract_ok :: {:ok, [binary], binary}
  @typep extract_err :: {:error, binary}

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
  @spec parse_header(binary(), options(), [atom()]) :: parse_result()

  def parse_header(data, options, required \\ []) do
    case extract_header(data, [], false) do
      {:ok, header_lines, rest_data} ->
        key_strings = options |> Keyword.keys() |> Enum.map(&Atom.to_string/1)

        kv_list =
          header_lines
          |> Enum.map(&split_kv/1)
          |> Enum.filter(fn {k, _} -> k in key_strings end)

        with [] <- find_missing(kv_list, required),
             {:ok, new_kv} <- transform_values(kv_list, options, []) do
          {:ok, {Map.new(new_kv), rest_data}}
        else
          error -> handle_error(error)
        end

      error ->
        handle_error(error)
    end
  end

  @spec handle_error(term) :: {:invalid, binary()}
  defp handle_error(term)

  defp handle_error([missing]) do
    {:invalid, "`#{missing}` is required, but it's missing"}
  end

  defp handle_error([_ | _] = missing) do
    repr = missing |> Enum.map(&"`#{&1}`") |> Enum.reverse() |> Enum.join(", ")

    {:invalid, "#{repr} are required, but they are missing"}
  end

  defp handle_error({:error, error}) do
    {:invalid, "header parse error: #{error}"}
  end

  @spec extract_header(binary, [binary], boolean) :: extract_ok | extract_err
  defp extract_header(data, acc, open?)

  defp extract_header(data, acc, false) do
    case String.split(data, ~r/\r?\n/, parts: 2) do
      ["---", rest] ->
        extract_header(rest, acc, true)

      [line, rest] when is_binary(line) ->
        extract_header(rest, acc, false)

      [_] ->
        {:error, "header not found"}
    end
  end

  defp extract_header(data, acc, true) do
    case String.split(data, ~r/\r?\n/, parts: 2) do
      ["---", rest] ->
        {:ok, acc, rest}

      [line, rest] when is_binary(line) ->
        extract_header(rest, [line | acc], true)

      [_] ->
        {:error, "encountered unexpected end of file"}
    end
  end

  @spec split_kv(binary) :: {binary, binary}

  defp split_kv(line) do
    case String.split(line, ":", parts: 2) do
      [x] -> {String.trim(x), ""}
      [k, v] -> {k, v}
    end
  end

  @spec find_missing([{binary, binary}], [atom]) :: [atom]

  defp find_missing(kvlist, required) do
    keys = Enum.map(kvlist, fn {k, _} -> k end)
    do_find_missing(keys, required)
  end

  @spec do_find_missing([binary], [atom], [atom]) :: [atom]

  defp do_find_missing(keys, required, acc \\ [])

  defp do_find_missing(_keys, [], acc) do
    acc
  end

  defp do_find_missing(keys, [h | t], acc) do
    if Atom.to_string(h) in keys do
      do_find_missing(keys, t, acc)
    else
      do_find_missing(keys, t, [h | acc])
    end
  end

  @spec transform_values([{binary, binary}], keyword(atom), keyword(value)) ::
          {:error, binary} | {:ok, keyword(value)}

  defp transform_values([], _options, acc) do
    {:ok, acc}
  end

  defp transform_values([{k, v} | rest], options, acc) do
    atom_k = String.to_existing_atom(k)

    case transform_value(k, String.trim(v), options[atom_k]) do
      {:error, _} = error -> error
      value -> transform_values(rest, options, [{atom_k, value} | acc])
    end
  end

  @spec transform_value(binary, binary, value_type) :: value | {:error, binary}

  defp transform_value(_key, valstr, :string) do
    valstr
  end

  defp transform_value(key, valstr, :integer) do
    case Integer.parse(valstr) do
      {value, ""} -> value
      _ -> {:error, "`#{key}`: invalid integer"}
    end
  end

  defp transform_value(key, valstr, :datetime) do
    case Timex.parse(valstr, @date_format1) do
      {:ok, dt} ->
        dt |> Timex.to_erl() |> Timex.to_datetime(:local)

      {:error, _msg} ->
        case Timex.parse(valstr, @date_format2) do
          {:ok, dt} ->
            dt |> Timex.to_erl() |> Timex.to_datetime(:local)

          {:error, msg} ->
            {:error, "`#{key}`: " <> msg}
        end
    end
  end

  defp transform_value(key, _valstr, {:list, {:list, _type}}) do
    {:error, "`#{key}`: \"list of lists\" type is not supported"}
  end

  defp transform_value(key, valstr, {:list, type}) when is_atom(type) do
    list =
      valstr
      |> String.split(",")
      |> Stream.map(&String.trim/1)
      |> Stream.reject(&(&1 == ""))
      |> Stream.map(&transform_value(key, &1, type))

    case Enum.filter(list, &error?/1) do
      [] -> Enum.to_list(list)
      [{:error, _} = error | _] -> error
    end
  end

  defp transform_value(key, _valstr, _type) do
    {:error, "`#{key}`: invalid value type"}
  end

  @spec error?(term) :: boolean

  defp error?({:error, _}), do: true
  defp error?(_), do: false
end
