defmodule Serum.HeaderParser.Extract do
  @moduledoc false

  _moduledocp = "Extracts header lines from the input text data."

  require Serum.V2.Result, as: Result
  alias Serum.Error

  @spec extract_header(binary()) ::
          Result.t({[{{binary(), binary()}, integer()}], binary(), integer()})
  def extract_header(data) do
    case do_extract_header(data, [], 1, false) do
      {:ok, {header, rest, next_line}} ->
        kvs = Enum.map(header, fn {str, line} -> {split_kv(str), line} end)

        Result.return({kvs, rest, next_line})

      {:error, %Error{}} = error ->
        error
    end
  end

  @typep indexed_line :: {binary(), integer()}

  @spec do_extract_header(binary(), [indexed_line()], integer(), boolean()) ::
          Result.t({[indexed_line()], binary(), integer()})
  defp do_extract_header(data, acc, line, open?)

  defp do_extract_header(data, acc, line, false) do
    case String.split(data, ~r/\r?\n/, parts: 2) do
      ["---", rest] -> do_extract_header(rest, acc, line + 1, true)
      [_str, rest] -> do_extract_header(rest, acc, line + 1, false)
      [_] -> Result.fail(Simple: ["header not found"], line: line - 1)
    end
  end

  defp do_extract_header(data, acc, line, true) do
    case String.split(data, ~r/\r?\n/, parts: 2) do
      ["---", rest] -> Result.return({acc, rest, line + 1})
      [str, rest] -> do_extract_header(rest, [{str, line} | acc], line + 1, true)
      [_] -> Result.fail(Simple: ["reached unexpected end of file"], line: line - 1)
    end
  end

  @spec split_kv(binary()) :: {binary(), binary()}
  defp split_kv(str) do
    str
    |> String.split(":", parts: 2)
    |> Enum.map(&String.trim/1)
    |> case do
      [key] -> {key, ""}
      [key, value] -> {key, value}
    end
  end
end
