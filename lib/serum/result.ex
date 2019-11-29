defmodule Serum.Result do
  @moduledoc """
  This module defines types for positive results or errors returned by
  functions in this project.
  """

  import Serum.IOProxy, only: [put_err: 2]
  alias Serum.Error
  alias Serum.Error.Format
  alias Serum.Error.SimpleMessage

  @type t(type) :: {:ok, type} | error()

  @type error :: {:error, err_details()}
  @type err_details :: msg_detail() | full_detail() | nest_detail() | Error.t()
  @type msg_detail :: binary()
  @type full_detail :: {binary(), binary(), non_neg_integer()}
  @type nest_detail :: {term(), [error()]}

  @doc """
  Takes a list of results with values and checks if there is no error.

  If there is no error, it returns `{:ok, list}` where `list` is a list of
  returned values.

  Returns an aggregated error object if there is one or more errors.
  """
  @spec aggregate_values([t(term())], term()) :: t([term()])
  def aggregate_values(results, msg) do
    results
    |> do_aggregate_values([], [])
    |> case do
      {values, []} ->
        {:ok, values}

      {_, errors} when is_list(errors) ->
        {:error, %Error{message: %SimpleMessage{text: msg}, caused_by: errors}}
    end
  end

  @spec do_aggregate_values([t(term())], [term()], [t(term())]) :: {[term()], [t(term())]}
  defp do_aggregate_values(results, values, errors)

  defp do_aggregate_values([], values, errors) do
    {Enum.reverse(values), errors |> Enum.reverse() |> Enum.uniq()}
  end

  defp do_aggregate_values([{:ok, value} | results], values, errors) do
    do_aggregate_values(results, [value | values], errors)
  end

  defp do_aggregate_values([{:error, _} = error | results], values, errors) do
    do_aggregate_values(results, values, [error | errors])
  end

  @doc "Prints an error object in a beautiful format."
  @spec show(t(term()), non_neg_integer()) :: {:ok, {}}
  def show(result, indent \\ 0)
  def show({:ok, _} = result, depth), do: put_err(:info, get_message(result, depth))
  def show(error, depth), do: put_err(:error, get_message(error, depth))

  @doc """
  Gets a human friendly message from the given `result`.

  You can control the indentation level by passing a non-negative integer to
  the `depth` parameter.
  """
  @spec get_message(t(term), non_neg_integer()) :: binary()
  def get_message(result, depth) do
    result |> do_get_message(depth) |> IO.iodata_to_binary()
  end

  @spec do_get_message(t(term), non_neg_integer()) :: IO.chardata()
  defp do_get_message(result, depth)
  defp do_get_message({:ok, _}, depth), do: indented("No error detected", depth)

  defp do_get_message({:error, msg}, depth) when is_binary(msg) do
    indented(msg, depth)
  end

  defp do_get_message({:error, {posix, file, line}}, depth) when is_atom(posix) do
    msg = posix |> :file.format_error() |> IO.iodata_to_binary()

    do_get_message({:error, {msg, file, line}}, depth)
  end

  defp do_get_message({:error, {msg, file, 0}}, depth) when is_binary(msg) do
    indented([file, ": ", msg], depth)
  end

  defp do_get_message({:error, {msg, file, line}}, depth) when is_binary(msg) do
    indented([file, ?:, to_string(line), ": ", msg], depth)
  end

  defp do_get_message({:error, {msg, errors}}, depth) when is_list(errors) do
    head = indented([:bright, :red, to_string(msg), ?:, :reset], depth)
    children = Enum.map(errors, &do_get_message(&1, depth + 1))

    [head | children] |> Enum.intersperse(?\n) |> IO.ANSI.format()
  end

  defp do_get_message({:error, %Error{} = error}, depth) do
    error |> Format.format_text(depth) |> IO.ANSI.format()
  end

  @spec indented(IO.ANSI.ansidata(), non_neg_integer()) :: IO.ANSI.ansidata()
  defp indented(str, 0), do: str
  defp indented(str, depth), do: [List.duplicate("  ", depth - 1), :red, "- ", :reset, str]

  @doc "Provides \"do-notation\"-like syntactic sugar for operation chaining."
  defmacro run(expr), do: build_run(expr)

  defp build_run(do: do_expr) do
    default_else =
      quote do
        {:error, %Serum.Error{}} = error -> error
      end

    build_run(do: do_expr, else: default_else)
  end

  defp build_run(do: {:__block__, _, exprs}, else: else_expr) do
    [last | leadings] = Enum.reverse(exprs)

    leadings =
      leadings
      |> Enum.reverse()
      |> Enum.map(fn
        {:<-, _, [lhs, rhs]} -> quote(do: {:ok, unquote(lhs)} <- unquote(rhs))
        {:=, _, _} = assignment -> assignment
        expr -> quote(do: {:ok, _} <- unquote(expr))
      end)

    quote do
      with(unquote_splicing(leadings), do: unquote(last), else: unquote(else_expr))
    end
  end

  @doc "Wraps `expr` into `{:ok, expr}` tuple."
  defmacro return(expr)
  defmacro return(do: do_block), do: quote(do: {:ok, unquote(do_block)})
  defmacro return(expr), do: quote(do: {:ok, unquote(expr)})
end
