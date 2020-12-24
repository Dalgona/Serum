defmodule Serum.ForeignCode do
  @moduledoc false

  _moduledocp = """
  Defines functions or macros for safely calling functions from modules
  defined outside Serum, such as third-party plugins or themes.
  """

  require Serum.V2.Result, as: Result
  alias Serum.V2.Error

  @spec call(Macro.t(), Macro.t()) :: Macro.t()
  defmacro call(call_expr, do: do_block) do
    {module, fun, _args} = handle_call_expr(call_expr)

    case_clauses =
      quote do
        {:error, %Error{} = error} ->
          Result.fail("#{fun_repr} returned an error:", caused_by: [error])

        term ->
          Result.fail("#{fun_repr} returned an unexpected value: #{inspect(term)}")
      end

    case_expr = {:case, [], [call_expr, [do: handle_do_block(do_block) ++ case_clauses]]}

    quote do
      fun_repr = "#{unquote(__MODULE__).module_name(unquote(module))}.#{to_string(unquote(fun))}"

      try do
        unquote(case_expr)
      rescue
        exception -> Result.from_exception(exception)
      end
    end
  end

  @spec handle_call_expr(Macro.t()) :: {module(), atom(), list()}
  defp handle_call_expr(call_expr)
  defp handle_call_expr({{:., _, [module, fun]}, _, args}), do: {module, fun, args}
  defp handle_call_expr({:apply, _, [module, fun, args]}), do: {module, fun, args}

  @spec handle_do_block(Macro.t()) :: Macro.t()
  defp handle_do_block(do_block) do
    Enum.map(do_block, fn {:->, _, [[lhs], rhs]} -> {:->, [], [[{:ok, lhs}], rhs]} end)
  end

  @spec module_name(module()) :: binary()
  def module_name(module) do
    module |> to_string() |> String.replace_prefix("Elixir.", "")
  end
end
