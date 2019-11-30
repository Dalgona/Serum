defmodule Serum.Template.Compiler.Include do
  @moduledoc false

  _moduledocp = "Provides functions for expanding includes in templates."

  require Serum.Result, as: Result
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
      {new_template, %{error: nil}} -> {:ok, new_template}
      {_, %{error: {:error, _} = error}} -> error
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
      {:error, _} = error -> {t, %{context | error: error}}
      {_, %{error: {:error, _} = error}} -> {t, %{context | error: error}}
    end
  end

  @spec prewalk_fun(Macro.t(), context()) :: {Macro.t(), context()}
  defp prewalk_fun(ast, context)
  defp prewalk_fun(ast, %{error: e} = ctx) when not is_nil(e), do: {ast, ctx}

  defp prewalk_fun({:include, _, [arg]} = ast, context) do
    case TS.get(arg, :include) do
      %Template{} = include ->
        {new_include, new_context} = do_expand(include, context)

        {quote(do: (fn -> unquote(new_include.ast) end).()), new_context}

      nil ->
        message = "include not found: \"#{arg}\""

        {ast, %{context | error: {:error, {message, context.template.file, 0}}}}
    end
  end

  defp prewalk_fun(ast, context), do: {ast, context}

  @spec check_cycle(binary(), context()) :: Result.t({})
  defp check_cycle(name, context) do
    if name in context.stack do
      graph =
        context.stack
        |> Enum.reverse()
        |> Enum.drop_while(&(&1 != name))
        |> make_graph()

      message = [
        "cycle detected while expanding includes:\n",
        graph,
        "  Cycles are not allowed when recursively including templates.\n",
        "  Please refactor your templates to break the cycle.\n",
        "  Alternatively, you can use the render/1,2 template helper.\n"
      ]

      {:error, {IO.iodata_to_binary(message), context.template.file, 0}}
    else
      Result.return()
    end
  end

  endl = [:reset, ?\n]
  top = ["    ", :red, "\u256d\u2500\u2500\u2500\u2500\u2500\u256e", endl]
  arrow = ["    ", :red, "\u2502     \u2193", endl]
  first_text = ["    ", :red, "\u2502    ", :yellow]
  rest_text = ["    ", :red, "\u2502    "]
  bottom1 = ["    ", :red, "\u2502     \u2502", endl]
  bottom2 = ["    ", :red, "\u2570\u2500\u2500\u2500\u2500\u2500\u256f", endl]

  @spec make_graph([binary()]) :: iodata()
  defp make_graph([first | rest]) do
    rest_graph =
      Enum.map(rest, fn name ->
        [
          unquote(arrow),
          unquote(rest_text),
          name,
          unquote(endl)
        ]
      end)

    [
      unquote(top),
      unquote(arrow),
      unquote(first_text),
      first,
      unquote(endl),
      rest_graph,
      unquote(bottom1),
      unquote(bottom2)
    ]
    |> IO.ANSI.format()
  end
end
