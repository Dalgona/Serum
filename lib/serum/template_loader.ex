defmodule Serum.TemplateLoader do
  @moduledoc """
  This module handles template loading and preprocessing.
  """

  import Serum.Util
  alias Serum.Result
  alias Serum.Template

  @type templates() :: %{optional(binary()) => Template.t()}

  @doc """
  Compiles and preprocesses the site templates.

  May return a map with loaded template ASTs.
  """
  @spec load_templates([Serum.File.t()]) :: Result.t()
  def load_templates(files) do
    result =
      files
      |> Task.async_stream(&compile_template/1)
      |> Enum.map(&elem(&1, 1))
      |> Result.aggregate_values(:template_loader)

    case result do
      {:ok, list} -> list |> Map.new() |> Template.load(:template)
      {:error, _} = error -> error
    end
  end

  @spec compile_template(Serum.File.t()) :: Result.t({binary(), Template.t()})
  defp compile_template(file) do
    path = file.src
    name = Path.basename(path, ".html.eex")

    case compile(file.in_data, :template) do
      {:ok, ast} -> {:ok, {name, Template.new(ast, :template, path)}}
      {:ct_error, msg, line} -> {:error, {msg, path, line}}
    end
  end

  @doc """
  Compiles and preprocesses the includable templates.

  May return a map with compiled includable templates.
  """
  @spec load_includes([Serum.File.t()]) :: Result.t()
  def load_includes(files) do
    result =
      files
      |> Task.async_stream(&compile_include/1)
      |> Enum.map(&elem(&1, 1))
      |> Result.aggregate_values(:template_loader)

    case result do
      {:ok, list} -> list |> Map.new() |> Template.load(:include)
      {:error, _} = error -> error
    end
  end

  @spec compile_include(Serum.File.t()) :: Result.t({binary(), Template.t()})
  defp compile_include(file) do
    path = file.src
    name = Path.basename(path, ".html.eex")

    case compile(file.in_data, :include) do
      {:ok, ast} -> {:ok, {name, Template.new(ast, :include, path)}}
      {:ct_error, msg, line} -> {:error, {msg, path, line}}
    end
  end

  @spec compile(binary(), Template.template_type()) ::
          {:ok, Macro.t()}
          | {:ct_error, binary, integer}
  def compile(data, kind) do
    compiled = EEx.compile_string(data)

    ast =
      case kind do
        :template ->
          compiled
          |> Macro.postwalk(&expand_includes/1)
          |> Macro.postwalk(&eval_helpers/1)

        :include ->
          compiled
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

  @spec eval_helpers(Macro.t()) :: Macro.t()
  defp eval_helpers(ast)

  defp eval_helpers({:base, _, []}) do
    quote do: unquote(base())
  end

  defp eval_helpers({:base, _, [arg]}) do
    quote do: Path.join(unquote(base()), unquote(arg))
  end

  defp eval_helpers({:page, _, [arg]}) do
    quote do: Path.join(unquote(base()), unquote(arg) <> ".html")
  end

  defp eval_helpers({:post, _, [arg]}) do
    quote do: Path.join([unquote(base()), "posts", unquote(arg) <> ".html"])
  end

  defp eval_helpers({:asset, _, [arg]}) do
    quote do: Path.join([unquote(base()), "assets", unquote(arg)])
  end

  defp eval_helpers(anything_else) do
    anything_else
  end

  defp base, do: quote(do: get_in(var!(assigns), [:site, :base_url]))
end
