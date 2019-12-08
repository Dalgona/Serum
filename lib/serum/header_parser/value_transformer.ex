defmodule Serum.HeaderParser.ValueTransformer do
  @moduledoc false

  _moduledocp = """
  A module for parsing header strings and transforming into appropriate types.
  """

  alias Serum.HeaderParser

  @typep kv :: {binary(), binary()}
  @typep type :: HeaderParser.value_type()

  @date_format1 "{YYYY}-{0M}-{0D} {h24}:{m}:{s}"
  @date_format2 "{YYYY}-{0M}-{0D}"

  @spec transform_value(kv(), type()) :: HeaderParser.value() | {:error, binary()}
  def transform_value(kv, type)
  def transform_value({_key, valstr}, :string), do: valstr

  def transform_value({key, valstr}, :integer) do
    case Integer.parse(valstr) do
      {value, ""} -> value
      _ -> {:error, "`#{key}`: invalid integer"}
    end
  end

  def transform_value({key, valstr}, :datetime) do
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

  def transform_value({key, _valstr}, {:list, {:list, _type}}) do
    {:error, "`#{key}`: \"list of lists\" type is not supported"}
  end

  def transform_value({key, valstr}, {:list, type}) when is_atom(type) do
    list =
      valstr
      |> String.split(",")
      |> Stream.map(&String.trim/1)
      |> Stream.reject(&(&1 == ""))
      |> Stream.map(&transform_value({key, &1}, type))

    case Enum.filter(list, &error?/1) do
      [] -> Enum.to_list(list)
      [{:error, _} = error | _] -> error
    end
  end

  def transform_value({key, _valstr}, _type) do
    {:error, "`#{key}`: invalid value type"}
  end

  @spec error?(term) :: boolean
  defp error?({:error, _}), do: true
  defp error?(_), do: false
end
