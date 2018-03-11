defmodule Serum.TemplateLoader do
  @moduledoc """
  This module handles template loading and preprocessing.
  """

  import Serum.Util
  alias Serum.Result
  alias Serum.Template

  @type templates() :: %{optional(binary()) => Template.t()}

  @doc """
  Reads, compiles, and preprocesses the site templates.

  May return a map with loaded template ASTs.
  """
  @spec load_templates(binary()) :: Result.t()
  def load_templates(src) do
    IO.puts("Loading templates...")

    result =
      ["base", "list", "page", "post"]
      |> Enum.map(&do_load_templates(&1, src))
      |> Result.aggregate_values(:load_templates)

    case result do
      {:ok, list} -> list |> Map.new() |> Template.load(:template)
      {:error, _} = error -> error
    end
  end

  @spec do_load_templates(binary(), binary()) :: Result.t({binary(), Template.t()})
  defp do_load_templates(name, src) do
    path = Path.join([src, "templates", name <> ".html.eex"])

    with {:ok, data} <- File.read(path),
         {:ok, ast} <- compile(data, :template) do
      {:ok, {name, Template.new(ast, :template, path)}}
    else
      {:error, reason} -> {:error, {reason, path, 0}}
      {:ct_error, msg, line} -> {:error, {msg, path, line}}
    end
  end

  @doc """
  Reads, compiles and preprocesses the includable templates.

  May return a map with compiled includable templates.
  """
  @spec load_includes(binary()) :: Result.t(templates())
  def load_includes(src) do
    IO.puts("Loading includes...")
    includes_dir = Path.join(src, "includes")

    if File.exists?(includes_dir) do
      result =
        includes_dir
        |> File.ls!()
        |> Stream.filter(&String.ends_with?(&1, ".html.eex"))
        |> Stream.map(&String.replace_suffix(&1, ".html.eex", ""))
        |> Stream.map(&do_load_includes(&1, src))
        |> Result.aggregate_values(:load_includes)

      case result do
        {:ok, list} -> list |> Map.new() |> Template.load(:include)
        {:error, _} = error -> error
      end
    else
      {:ok, %{}}
    end
  end

  @spec do_load_includes(binary(), binary()) :: Result.t({binary(), Template.t()})
  defp do_load_includes(name, src) do
    path = Path.join([src, "includes", name <> ".html.eex"])

    with {:ok, data} <- File.read(path),
         {:ok, ast} <- compile(data, :include) do
      {:ok, {name, Template.new(ast, :include, path)}}
    else
      {:error, reason} -> {:error, {reason, path, 0}}
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
        :template -> preprocess_template(compiled)
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

  @spec preprocess_template(Macro.t()) :: Macro.t()
  defp preprocess_template(ast) do
    ast
    |> Macro.postwalk(&expand_includes/1)
    |> Macro.postwalk(&eval_helpers/1)
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
