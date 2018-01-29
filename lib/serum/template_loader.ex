defmodule Serum.TemplateLoader do
  @moduledoc """
  This module handles template loading and preprocessing.
  """

  import Serum.Util
  alias Serum.Error

  @type templates() :: %{optional(binary()) => Macro.t()}

  @doc """
  Reads, compiles, and preprocesses the site templates.

  May return a map with loaded template ASTs.
  """
  @spec load_templates(binary(), templates()) :: Error.result(templates())
  def load_templates(src, includes) do
    IO.puts "Loading templates..."
    result =
      ["base", "list", "page", "post"]
      |> Enum.map(&do_load_templates(&1, src, includes))
      |> Error.filter_results_with_values(:load_templates)
    case result do
      {:ok, list} -> {:ok, Map.new(list)}
      {:error, _} = error -> error
    end
  end

  @spec do_load_templates(binary(), binary(), binary())
    :: Error.result({binary(), Macro.t()})
  defp do_load_templates(name, src, includes) do
    path = Path.join [src, "templates", name <> ".html.eex"]
    with {:ok, data} <- File.read(path),
         {:ok, ast} <- compile(data, :template, includes: includes)
    do
      {:ok, {name, ast}}
    else
      {:error, reason} -> {:error, {reason, path, 0}}
      {:ct_error, msg, line} -> {:error, {msg, path, line}}
    end
  end

  @doc """
  Reads, compiles and preprocesses the includable templates.

  May return a map with compiled includable templates.
  """
  @spec load_includes(binary()) :: Error.result(templates())
  def load_includes(src) do
    IO.puts "Loading includes..."
    includes_dir = Path.join src, "includes"
    if File.exists? includes_dir do
      result =
        includes_dir
        |> File.ls!
        |> Stream.filter(&String.ends_with?(&1, ".html.eex"))
        |> Stream.map(&String.replace_suffix(&1, ".html.eex", ""))
        |> Stream.map(&do_load_includes(&1, src))
        |> Error.filter_results_with_values(:load_includes)
      case result do
        {:ok, list} -> {:ok, Map.new(list)}
        {:error, _} = error -> error
      end
    else
      {:ok, %{}}
    end
  end

  @spec do_load_includes(binary(), binary()) :: Error.result({binary(), Macro.t()})
  defp do_load_includes(name, src) do
    path = Path.join [src, "includes", name <> ".html.eex"]
    with {:ok, data} <- File.read(path),
         {:ok, ast} <- compile(data, :include)
    do
      {:ok, {name, ast}}
    else
      {:error, reason} -> {:error, {reason, path, 0}}
      {:ct_error, msg, line} -> {:error, {msg, path, line}}
    end
  end

  @spec compile(binary(), :template | :include, keyword())
    :: {:ok, Macro.t}
     | {:ct_error, binary, integer}
  def compile(data, kind, args \\ []) do
    compiled = EEx.compile_string(data)
    ast =
      case kind do
        :template -> preprocess_template(compiled, args[:includes])
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

  @spec preprocess_template(Macro.t(), templates()) :: Macro.t()
  defp preprocess_template(ast, includes) do
    ast
    |> Macro.postwalk(&expand_includes(&1, includes))
    |> Macro.postwalk(&eval_helpers/1)
  end

  @spec expand_includes(Macro.t(), templates()) :: Macro.t()
  defp expand_includes(ast, includes)

  defp expand_includes({:include, _, [arg]}, includes) do
    case includes[arg] do
      nil ->
        warn "There is no includable template named `#{arg}`."
        nil
      ast -> ast
    end
  end

  defp expand_includes(anything_else, _) do
    anything_else
  end

  @spec eval_helpers(Macro.t()) :: Macro.t()
  defp eval_helpers(ast)

  defp eval_helpers({:base, _, []}) do
    quote do: var!(base_url)
  end

  defp eval_helpers({:base, _, [arg]}) do
    quote do: Path.join(var!(base_url), unquote(arg))
  end

  defp eval_helpers({:page, _, [arg]}) do
    quote do: Path.join(var!(base_url), unquote(arg) <> ".html")
  end

  defp eval_helpers({:post, _, [arg]}) do
    quote do: Path.join([var!(base_url), "posts", unquote(arg) <> ".html"])
  end

  defp eval_helpers({:asset, _, [arg]}) do
    quote do: Path.join([var!(base_url), "assets", unquote(arg)])
  end

  defp eval_helpers(anything_else) do
    anything_else
  end
end
