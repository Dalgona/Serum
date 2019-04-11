defmodule Serum.Template.Compiler do
  @moduledoc """
  This module handles template loading and preprocessing.
  """

  import Serum.Util
  alias Serum.Plugin
  alias Serum.Result
  alias Serum.Template

  @type templates() :: %{optional(binary()) => Template.t()}

  @inject """
  <%
  require Serum.Template.Helpers
  import Serum.Template.Helpers
  %>
  """

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
    injected_file = %Serum.File{file | in_data: @inject <> file.in_data}

    with {:ok, file2} <- Plugin.processing_template(injected_file),
         {:ok, ast} <- compile_string(file2.in_data, type),
         template = Template.new(ast, type, file2.src),
         name = Path.basename(file2.src, ".html.eex"),
         {:ok, template2} <- Plugin.processed_template(template) do
      {:ok, {name, template2}}
    else
      {:ct_error, msg, line} -> {:error, {msg, file.src, line}}
      {:error, _} = plugin_error -> plugin_error
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

    e in [SyntaxError, TokenMissingError] ->
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
        quote do: (fn -> unquote(include.ast) end).()
    end
  end

  defp expand_includes(anything_else), do: anything_else
end
