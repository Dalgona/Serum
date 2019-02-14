defmodule Serum.TemplateCompiler do
  @moduledoc """
  This module handles template loading and preprocessing.
  """

  import Serum.Util
  alias Serum.Result
  alias Serum.Template

  @type templates() :: %{optional(binary()) => Template.t()}

  @spec compile_files([Serum.File.t()], Template.template_type()) :: Result.t(map())
  def compile_files(files, type) do
    result =
      files
      |> Task.async_stream(&compile_file(&1, type))
      |> Enum.map(&elem(&1, 1))
      |> Result.aggregate_values(:template_loader)

    case result do
      {:ok, list} -> {:ok, Map.new(list)}
      {:error, _} = error -> error
    end
  end

  @spec compile_file(Serum.File.t(), Template.template_type()) ::
          Result.t({binary(), Template.t()})
  defp compile_file(file, type) do
    path = file.src
    name = Path.basename(path, ".html.eex")

    inject = """
    <%
    require Serum.TemplateHelpers
    import Serum.TemplateHelpers
    %>
    """

    case compile_string(inject <> file.in_data, type) do
      {:ok, ast} -> {:ok, {name, Template.new(ast, type, path)}}
      {:ct_error, msg, line} -> {:error, {msg, path, line}}
    end
  end

  @spec compile_string(binary(), Template.template_type()) ::
          {:ok, Macro.t()}
          | {:ct_error, binary, integer}
  def compile_string(data, kind) do
    compiled = EEx.compile_string(data)

    ast =
      case kind do
        :template -> Macro.postwalk(compiled, &expand_includes/1)
        :include -> compiled
      end

    {:ok, ast}
  rescue
    e in EEx.SyntaxError ->
      {:ct_error, e.message, e.line}

    e in SyntaxError ->
      {:ct_error, e.description, e.line}

    e in TokenMissingError ->
      {:ct_error, e.description, e.line}
  end

  @spec expand_includes(Macro.t()) :: Macro.t()
  defp expand_includes(ast)

  defp expand_includes({:include, _, [arg]}) do
    case Template.get(arg, :include) do
      nil ->
        warn("There is no includable template named `#{arg}`.")
        nil

      include ->
        include.ast
    end
  end

  defp expand_includes(anything_else), do: anything_else
end
