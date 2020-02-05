defmodule Serum.Result do
  @moduledoc """
  This module defines types for positive results or errors returned by
  functions in this project.
  """

  import Serum.IOProxy, only: [put_err: 2]
  alias Serum.Error
  alias Serum.Error.Format
  alias Serum.Error.SimpleMessage

  @type t(type) :: {:ok, type} | {:error, Error.t()}

  @doc """
  Takes a list of results with values and checks if there is no error.

  If there is no error, it returns `{:ok, list}` where `list` is a list of
  returned values.

  Returns an aggregated error object if there is one or more errors.
  """
  @spec aggregate([t(a)], binary()) :: t([a]) when a: term()
  def aggregate(results, msg) do
    results
    |> do_aggregate([], [])
    |> case do
      {values, []} when is_list(values) ->
        {:ok, values}

      {_, errors} when is_list(errors) ->
        {:error, %Error{message: %SimpleMessage{text: msg}, caused_by: errors}}
    end
  end

  @spec do_aggregate([t(a)], [a], [Error.t()]) :: {[a], [Error.t()]} when a: term()
  defp do_aggregate(results, values, errors)

  defp do_aggregate([], values, errors) do
    {Enum.reverse(values), errors |> Enum.reverse() |> Enum.uniq()}
  end

  defp do_aggregate([{:ok, value} | results], values, errors) do
    do_aggregate(results, [value | values], errors)
  end

  defp do_aggregate([{:error, error} | results], values, errors) do
    do_aggregate(results, values, [error | errors])
  end

  @doc "Prints an error object in a beautiful format."
  @spec show(t(term()), non_neg_integer()) :: t({})
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

  defp do_get_message({:error, %Error{} = error}, depth) do
    error |> Format.format_text(depth) |> IO.ANSI.format()
  end

  @spec indented(IO.ANSI.ansidata(), non_neg_integer()) :: IO.ANSI.ansidata()
  defp indented(str, 0), do: str
  defp indented(str, depth), do: [List.duplicate("  ", depth - 1), :red, "- ", :reset, str]

  @doc "Binds the value of the given `result` to `fun`."
  @spec bind(t(a), (a -> t(b))) :: t(b) when a: term(), b: term()
  def bind(result, fun)
  def bind({:ok, value}, fun), do: fun.(value)
  def bind({:error, %Error{}} = error, _fun), do: error

  @doc "Provides \"do-notation\"-like syntactic sugar for operation chaining."
  defmacro run(do: {:__block__, _, exprs}) when is_list(exprs) do
    exprs
    |> Enum.reverse()
    |> Enum.reduce(fn
      {:<-, _, [lhs, rhs]}, acc ->
        quote do
          Serum.Result.bind(unquote(rhs), fn unquote(lhs) -> unquote(acc) end)
        end

      {:=, _, _} = match, acc ->
        quote do
          unquote(match)
          unquote(acc)
        end

      expr, acc ->
        quote do
          Serum.Result.bind(unquote(expr), fn _ -> unquote(acc) end)
        end
    end)
  end

  @doc "Expands into `{:ok, {}}` tuple."
  defmacro return, do: quote(do: {:ok, {}})

  @doc "Wraps `expr` into `{:ok, expr}` tuple."
  defmacro return(expr)
  defmacro return(do: do_block), do: quote(do: {:ok, unquote(do_block)})
  defmacro return(expr), do: quote(do: {:ok, unquote(expr)})

  @doc "Expands into `{:error, %Error{...}}` tuple."
  defmacro fail([{msg_type, msg_args} | opts])
           when is_atom(msg_type) and is_list(msg_args) and is_list(opts) do
    msg_module = Module.concat(Serum.Error, "#{msg_type}Message")
    caused_by = opts[:caused_by] || []

    quote do
      {:error,
       %Serum.Error{
         message: unquote(msg_module).message(unquote(msg_args)),
         caused_by: unquote(caused_by),
         file: unquote(opts[:file]),
         line: unquote(opts[:line])
       }}
    end
  end

  defmacro fail({:__aliases__, _, [type]}, args, opts \\ [])
           when is_atom(type) and is_list(args) and is_list(opts) do
    msg_module = Module.concat(Serum.Error, "#{type}Message")
    caused_by = opts[:caused_by] || []

    quote do
      {:error,
       %Serum.Error{
         message: unquote(msg_module).message(unquote(args)),
         caused_by: unquote(caused_by),
         file: unquote(opts[:file]),
         line: unquote(opts[:line])
       }}
    end
  end
end
