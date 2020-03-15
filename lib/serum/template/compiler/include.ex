defmodule Serum.Template.Compiler.Include do
  @moduledoc false

  _moduledocp = "Provides functions for expanding includes in templates."

  require Serum.V2.Result, as: Result
  alias Serum.Error
  alias Serum.Template
  alias Serum.Template.Storage, as: TS

  @typep context :: %{
           template: Template.t(),
           stack: [binary()],
           error: Result.t({}) | nil
         }

  @spec expand(Template.t()) :: Result.t(Template.t())
  def expand(template) do
    initial_context = %{
      template: template,
      stack: [],
      error: nil
    }

    case do_expand(template, initial_context) do
      {new_template, %{error: nil}} -> Result.return(new_template)
      {_, %{error: {:error, %Error{}} = error}} -> error
    end
  end

  @spec do_expand(Template.t(), context()) :: {Template.t(), context()}
  defp do_expand(template, context)
  defp do_expand(%Template{include_resolved?: true} = t, ctx), do: {t, ctx}

  defp do_expand(%Template{name: name, type: type, ast: ast} = t, context) do
    next_context = %{context | template: t, stack: [name | context.stack]}

    with {:ok, _} <- check_cycle(name, context),
         walk_result = Macro.prewalk(ast, next_context, &prewalk_fun/2),
         {new_ast, %{error: nil} = new_context} <- walk_result do
      new_template = %Template{t | ast: new_ast, include_resolved?: true}

      TS.put(name, type, new_template)

      {new_template, new_context}
    else
      {:error, %Error{}} = error -> {t, %{context | error: error}}
      {_, %{error: {:error, %Error{}} = error}} -> {t, %{context | error: error}}
    end
  end

  @spec prewalk_fun(Macro.t(), context()) :: {Macro.t(), context()}
  defp prewalk_fun(ast, context)
  defp prewalk_fun(ast, %{error: e} = ctx) when not is_nil(e), do: {ast, ctx}

  defp prewalk_fun({:include, _, [arg]} = ast, context) do
    case TS.get(arg, :include) do
      {:ok, include} ->
        {new_include, new_context} = do_expand(include, context)

        {quote(do: (fn -> unquote(new_include.ast) end).()), new_context}

      {:error, %Error{} = error} ->
        error = %Error{error | file: context.template.file}

        {ast, %{context | error: {:error, error}}}
    end
  end

  defp prewalk_fun(ast, context), do: {ast, context}

  @spec check_cycle(binary(), context()) :: Result.t({})
  defp check_cycle(name, context) do
    if name in context.stack do
      cycle = context.stack |> Enum.reverse() |> Enum.drop_while(&(&1 != name))

      Result.fail(Cycle: [cycle], file: context.template.file)
    else
      Result.return()
    end
  end
end
