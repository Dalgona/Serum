defmodule Serum.V2.Result do
  @moduledoc """
  Defines a type, functions, and macros for working with operations that may
  succeed or fail.
  """

  alias Serum.V2.Error
  alias Serum.V2.Error.SimpleMessage

  @type t(type) :: {:ok, type} | {:error, Error.t()}

  @doc """
  Aggregates a list of results into a single result.

  If there is no error in the given list of results, `{:ok, values}` will be
  returned, where `values` is a list of value in each successful result.

  If there are one or more errors in the given list of results, this function
  will return an aggregrated error object.

  ## Examples

      iex> Serum.V2.Result.aggregate([{:ok, 1}, {:ok, 2}, {:ok, 3}], "")
      {:ok, [1, 2, 3]}

      iex> Serum.V2.Result.aggregate(
      ...>   [{:ok, 1}, {:error, Error1}, {:error, Error2}],
      ...>   "one or more errors occurred"
      ...> )
      {:error,
       %Serum.V2.Error{
         message: %Serum.V2.Error.SimpleMessage{
           text: "one or more errors occurred"
         },
         caused_by: [Error1, Error2],
         file: nil,
         line: nil
       }}
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

  @doc "Binds the value of the given `result` to `fun`."
  @spec bind(t(a), (a -> t(b))) :: t(b) when a: term(), b: term()
  def bind(result, fun)
  def bind({:ok, value}, fun), do: fun.(value)
  def bind({:error, %Error{}} = error, _fun), do: error

  @doc """
  Provides a convenient syntax for working with a chain of functions returning
  values in the `t:Serum.Result.t/1` type.
  """
  defmacro run(do: {:__block__, _, exprs}) when is_list(exprs) do
    exprs
    |> Enum.reverse()
    |> Enum.reduce(fn
      {:<-, _, [lhs, rhs]}, acc ->
        quote do
          Serum.V2.Result.bind(unquote(rhs), fn unquote(lhs) -> unquote(acc) end)
        end

      {:=, _, _} = match, acc ->
        quote do
          unquote(match)
          unquote(acc)
        end

      expr, acc ->
        quote do
          Serum.V2.Result.bind(unquote(expr), fn _ -> unquote(acc) end)
        end
    end)
  end

  @doc """
  Creates a successful result with no returned value.

  Expands into `{:ok, {}}` tuple.
  """
  defmacro return, do: quote(do: {:ok, {}})

  @doc """
  Creates a successful result with a returned value.

  ## Examples

      # Returning a simple expression
      iex> Serum.V2.Result.return(42)
      {:ok, 42}

      # Returning a value calculated by the given `do`-block
      iex> Serum.V2.Result.return do
      ...>   x = 21
      ...>   x * 2
      ...> end
      {:ok, 42}
  """
  defmacro return(expr)
  defmacro return(do: do_block), do: quote(do: {:ok, unquote(do_block)})
  defmacro return(expr), do: quote(do: {:ok, unquote(expr)})

  @doc """
  Creates a result value indicating a failure.

  This function is a shortcut for creating a failed result with a simple,
  string-based error message, without any options.

  ## Example

      iex> Serum.V2.Result.fail("oh, no!")
      {:error,
       %Serum.V2.Error{
         message: %Serum.V2.Error.SimpleMessage{text: "oh, no!"},
         caused_by: [],
         file: nil,
         line: nil
       }}
  """
  @spec fail(binary()) :: Result.t(term())
  def fail(msg_string) when is_binary(msg_string), do: fail(msg_string, [])

  @doc """
  Creates a result value indicating a failure.

  This function has two usages:

  - `fail/3`, but without `options` keyword list

        iex> Serum.V2.Result.fail(POSIX, :enoent)
        {:error,
         %Serum.V2.Error{
           message: %Serum.V2.Error.POSIXMessage{reason: :enoent},
           caused_by: [],
           file: nil,
           line: nil
         }}

  - `fail/1`, but with an `options` keyword list

        iex> Serum.V2.Result.fail("oh, no!", file: %Serum.V2.File{}, line: 3)
        {:error,
        %Serum.V2.Error{
          message: %Serum.V2.Error.SimpleMessage{text: "oh, no!"},
          caused_by: [],
          file: %Serum.V2.File{},
          line: 3
        }}
  """
  @spec fail(binary() | atom(), keyword() | term()) :: Result.t(term())
  def fail(msg_type_or_msg_string, msg_arg_or_options)

  def fail(msg_string, options) when is_binary(msg_string) and is_list(options) do
    fail(Simple, msg_string, options)
  end

  def fail(msg_type, msg_arg) when is_atom(msg_type) do
    fail(msg_type, msg_arg, [])
  end

  @doc """
  Creates a result value indicating a failure.

  The first argument specifies which type of error message will be used.
  Possible values are:

  - `Constraint` (or `:Constraint`) for `Serum.V2.Error.ConstraintMessage`
  - `Cycle` (or `:Cycle`) for `Serum.V2.Error.CycleMessage`
  - `Exception` (or `:Exception`) for `Serum.V2.Error.ExceptionMessage`
  - `POSIX` (or `:POSIX`) for `Serum.V2.Error.POSIXMessage`
  - `Simple` (or `:Simple`) for `Serum.V2.Error.SimpleMessage`

  The second argument is passed to the error message constructor function.
  See the documentation for each error message struct listed above for more
  information.

  The third argument, which can be omitted, is a keyword list of options.
  Available options are:

  - `:caused_by` - a list of `Serum.V2.Error` structs which caused this failure.
  - `:file` - a `Serum.V2.File` struct which caused this failure.
  - `:line` - line number in a file specified by `options[:file]`. This is only
    meaningful when `options[:file]` is set to a valid `Serum.V2.File` struct.

  ## Examples

      iex> Serum.V2.Result.fail(Simple, "oh, no!")
      {:error,
       %Serum.V2.Error{
         message: %Serum.V2.Error.SimpleMessage{text: "oh, no!"},
         caused_by: [],
         file: nil,
         line: nil
       }}

      iex> Serum.V2.Result.fail(Simple, "oh, no!", file: %Serum.File{}, line: 3)
      {:error,
       %Serum.V2.Error{
         message: %Serum.V2.Error.SimpleMessage{text: "oh, no!"},
         caused_by: [],
         file: %Serum.V2.File{},
         line: 3
       }}
  """
  @spec fail(atom(), term(), keyword()) :: Result.t(term())
  def fail(msg_type, msg_arg, options) when is_atom(msg_type) and is_list(options) do
    {:error,
     %Error{
       message: Module.concat(Error, "#{msg_type}Message").message(msg_arg),
       caused_by: options[:caused_by] || [],
       file: options[:file],
       line: options[:line]
     }}
  end
end
