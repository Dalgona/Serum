defmodule Serum.HeaderParser do
  alias Serum.Error

  @type options :: [{atom, value_type}]
  @type value_type :: :string | :integer | {:list, value_type}
  @type value :: binary | integer | [binary] | [integer]

  @spec parse_header(IO.device, options, [atom]) :: Error.result(map)

  def parse_header(device, options, required \\ []) do
    case extract_header device, [], false do
      {:ok, lines} ->
        key_strings = options |> Keyword.keys |> Enum.map(&Atom.to_string/1)
        kv_list =
          lines
          |> Enum.map(&split_kv/1)
          |> Enum.filter(fn {k, _} -> k in key_strings end)
        with [] <- find_missing(kv_list, required),
             {:ok, new_kv} <- transform_values(kv_list, options, []) do
          {:ok, Map.new(new_kv)}
        else
          error -> handle_error error
        end
      {:error, error} ->
        {:error, :invalid_header,
         {"header parse error: #{error}", "nofile", 0}} # TODO: accept filename
    end
  end

  defp handle_error([missing]) do # TODO: accept filename
    {:error, :invalid_header,
     {"`#{missing}` field is required, but not specified.",
      "nofile", 0}}
  end

  defp handle_error([_|_] = missing) do # TODO: accept filename
    repr = missing |> Enum.map(&"`#{&1}`") |> Enum.join(", ")
    {:error, :invalid_header,
     {"#{repr} fields are required, but not specified.",
      "nofile", 0}}
  end

  defp handle_error({:error, error}) do # TODO: accept filename
    {:error, :invalid_header,
     {"header parse error: #{error}", "nofile", 0}}
  end

  @spec extract_header(IO.device, [binary], boolean)
    :: {:ok, [binary]} | {:error, binary}

  defp extract_header(device, lines, open?)

  defp extract_header(device, lines, false) do
    case IO.read device, :line do
      "===\n" ->
        extract_header device, lines, true
      line when is_binary(line) ->
        extract_header device, lines, false
      :eof ->
        {:error, "header not found"}
    end
  end

  defp extract_header(device, lines, true) do
    case IO.read device, :line do
      "===\n" ->
        {:ok, lines}
      line when is_binary(line) ->
        extract_header device, [line|lines], true
      :eof ->
        {:error, "unexpected end of file"}
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
    keys = Enum.map kvlist, fn {k, _} -> k end
    do_find_missing keys, required
  end

  @spec do_find_missing([binary], [atom], [atom]) :: [atom]

  defp do_find_missing(keys, required, acc \\ [])

  defp do_find_missing(_keys, [], acc) do
    acc
  end

  defp do_find_missing(keys, [h|t], acc) do
    if Atom.to_string(h) in keys do
      do_find_missing keys, t, acc
    else
      do_find_missing keys, t, [h|acc]
    end
  end

  @spec transform_values([{binary, binary}], keyword(atom), keyword(value))
    :: {:error, binary} | {:ok, keyword(value)}

  defp transform_values([], _options, acc) do
    {:ok, acc}
  end

  defp transform_values([{k, v}|rest], options, acc) do
    atom_k = String.to_existing_atom k
    case transform_value v, options[atom_k] do
      {:error, _} = error -> error
      value -> transform_values rest, options, [{atom_k, value}|acc]
    end
  end

  @spec transform_value(binary, value_type) :: value | {:error, binary}

  defp transform_value(valstr, :string) do
    valstr
  end

  defp transform_value(valstr, :integer) do
    case Integer.parse valstr do
      {value, ""} -> value
      _ -> {:error, "invalid integer"}
    end
  end

  defp transform_value(_valstr, {:list, {:list, _type}}) do
    {:error, "\"list of lists\" type is not supported"}
  end

  defp transform_value(valstr, {:list, type}) when is_atom(type) do
    list =
      valstr
      |> String.split(",")
      |> Stream.map(&String.trim/1)
      |> Stream.reject(& &1 == "")
      |> Stream.map(&transform_value &1, type)
    case Enum.filter list, &error?/1 do
      [] -> Enum.to_list list
      [{:error, _} = error|_] -> error
    end
  end

  defp transform_value(_valstr, _type) do
    {:error, "invalid value type"}
  end

  @spec error?(term) :: boolean

  defp error?({:error, _}), do: true
  defp error?(_), do: false
end
