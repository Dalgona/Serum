defmodule Serum.HeaderParser.ValueTransformer do
  @moduledoc false

  _moduledocp = """
  A module for parsing header strings and transforming into appropriate types.
  """

  require Serum.Result, as: Result
  alias Serum.Error
  alias Serum.HeaderParser

  @typep kv :: {binary(), binary()}
  @typep type :: HeaderParser.value_type()

  @date_format1 "{YYYY}-{0M}-{0D} {h24}:{m}:{s}"
  @date_format2 "{YYYY}-{0M}-{0D}"

  @spec transform_value(kv(), type(), integer()) :: Result.t(HeaderParser.value())
  def transform_value(kv, type, line \\ 0)

  def transform_value({_key, valstr}, :string, _line) do
    Result.return(valstr)
  end

  def transform_value({key, valstr}, :integer, line) do
    case Integer.parse(valstr) do
      {value, ""} -> Result.return(value)
      _ -> Result.fail(Simple, ["#{key}: invalid integer"], line: line)
    end
  end

  def transform_value({key, valstr}, :datetime, line) do
    case Timex.parse(valstr, @date_format1) do
      {:ok, dt} ->
        Result.return(local_datetime(dt))

      {:error, _msg} ->
        case Timex.parse(valstr, @date_format2) do
          {:ok, dt} -> Result.return(local_datetime(dt))
          {:error, msg} -> Result.fail(Simple, ["#{key}: " <> msg], line: line)
        end
    end
  end

  def transform_value({key, _valstr}, {:list, {:list, _type}}, line) do
    Result.fail(Simple, ["#{key}: \"list of lists\" type is not supported"], line: line)
  end

  def transform_value({key, valstr}, {:list, type}, line) when is_atom(type) do
    valstr
    |> String.split(",")
    |> Stream.map(&String.trim/1)
    |> Stream.reject(&(&1 == ""))
    |> Enum.map(&transform_value({key, &1}, type))
    |> Result.aggregate("#{key}: failed to parse list item(s):")
    |> case do
      {:ok, _} = result -> result
      {:error, %Error{} = error} -> {:error, %Error{error | line: line}}
    end
  end

  def transform_value({key, _valstr}, _type, line) do
    Result.fail(Simple, ["#{key}: invalid value type"], line: line)
  end

  @spec local_datetime(DateTime.t() | NaiveDateTime.t()) :: DateTime.t()
  defp local_datetime(dt) do
    dt |> Timex.to_erl() |> Timex.to_datetime(:local)
  end
end
