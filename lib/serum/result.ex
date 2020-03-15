defmodule Serum.Result do
  @moduledoc false

  import Serum.V2.Console, only: [put_err: 2]
  alias Serum.V2.Result
  alias Serum.Error
  alias Serum.Error.Format

  @doc "Prints an error object in a beautiful format."
  @spec show(Result.t(term()), non_neg_integer()) :: Result.t({})
  def show(result, indent \\ 0)
  def show({:ok, _} = result, depth), do: put_err(:info, get_message(result, depth))
  def show(error, depth), do: put_err(:error, get_message(error, depth))

  @doc """
  Gets a human friendly message from the given `result`.

  You can control the indentation level by passing a non-negative integer to
  the `depth` parameter.
  """
  @spec get_message(Result.t(term), non_neg_integer()) :: binary()
  def get_message(result, depth) do
    result |> do_get_message(depth) |> IO.iodata_to_binary()
  end

  @spec do_get_message(Result.t(term), non_neg_integer()) :: IO.chardata()
  defp do_get_message(result, depth)
  defp do_get_message({:ok, _}, depth), do: indented("No error detected", depth)

  defp do_get_message({:error, %Error{} = error}, depth) do
    error |> Format.format_text(depth) |> IO.ANSI.format()
  end

  @spec indented(IO.ANSI.ansidata(), non_neg_integer()) :: IO.ANSI.ansidata()
  defp indented(str, 0), do: str
  defp indented(str, depth), do: [List.duplicate("  ", depth - 1), :red, "- ", :reset, str]
end
