defmodule Serum.TemplateLoader do
  @moduledoc """
  This module handles template loading and preprocessing.
  """

  alias Serum.Build
  alias Serum.Error
  alias Serum.Renderer
  import Serum.Util

  @type state :: Build.state

  @doc """
  Reads, compiles, and preprocesses the site templates.

  May return a new state object with loaded template AST objects.
  """
  @spec load_templates(state) :: Error.result(state)

  def load_templates(state) do
    IO.puts "Loading templates..."
    result =
      ["base", "list", "page", "post"]
      |> Enum.map(&do_load_templates(&1, state))
      |> Error.filter_results_with_values(:load_templates)
    case result do
      {:ok, list} -> {:ok, Map.put(state, :templates, Map.new(list))}
      {:error, _, _} = error -> error
    end
  end

  @spec do_load_templates(binary, state) :: Error.result({binary, Macro.t})

  defp do_load_templates(name, state) do
    path = "#{state.src}templates/#{name}.html.eex"
    with {:ok, data} <- File.read(path),
         {:ok, ast} <- compile_template(data, state)
    do
      {:ok, {name, ast}}
    else
      {:error, reason} -> {:error, :file_error, {reason, path, 0}}
      {:error, msg, line} -> {:error, :invalid_template, {msg, path, line}}
    end
  end

  @doc """
  Reads, compiles, preprocesses, and renders the includable templates.

  May return a new state object with rendered HTML stub of includable templates.
  """
  @spec load_includes(state) :: Error.result(state)

  def load_includes(state) do
    IO.puts "Loading includes..."
    includes_dir = state.src <> "includes/"
    if File.exists? includes_dir do
      result =
        includes_dir
        |> File.ls!
        |> Stream.filter(&String.ends_with?(&1, ".html.eex"))
        |> Stream.map(&String.replace_suffix(&1, ".html.eex", ""))
        |> Stream.map(&do_load_includes(&1, state))
        |> Enum.map(&render_includes(&1, state))
        |> Error.filter_results_with_values(:load_includes)
      case result do
        {:ok, list} -> {:ok, Map.put(state, :includes, Map.new(list))}
        {:error, _, _} = error -> error
      end
    else
      {:ok, Map.put(state, :includes, %{})}
    end
  end

  @spec do_load_includes(binary, state) :: Error.result({binary, Macro.t})

  defp do_load_includes(name, state) do
    path = "#{state.src}includes/#{name}.html.eex"
    with {:ok, data} <- File.read(path),
         {:ok, ast} <- compile_template(data, state)
    do
      {:ok, {name, ast}}
    else
      {:error, reason} -> {:error, :file_error, {reason, path, 0}}
      {:error, msg, line} -> {:error, :invalid_template, {msg, path, line}}
    end
  end

  @spec render_includes(Error.result({binary, Macro.t}), state)
    :: Error.result({binary, binary})

  defp render_includes({:ok, {name, ast}}, state) do
    case Renderer.render_stub ast, state.site_ctx, name do
      {:ok, html} -> {:ok, {name, html}}
      {:error, _, _} = error -> error
    end
  end

  defp render_includes(error = {:error, _, _}, _state) do
    error
  end

  @doc """
  Compiles a given EEx string into an Elixir AST and preprocesses Serum template
  helper macros.

  Returns `{:ok, template_ast}` if there is no error.
  """
  @spec compile_template(binary, state)
    :: {:ok, Macro.t}
     | {:error, binary, integer}

  def compile_template(data, state) do
    try do
      ast = data |> EEx.compile_string() |> preprocess_template(state)
      {:ok, ast}
    rescue
      e in EEx.SyntaxError ->
        {:error, e.message, e.line}
      e in SyntaxError ->
        {:error, e.description, e.line}
      e in TokenMissingError ->
        {:error, e.description, e.line}
    end
  end

  @spec preprocess_template(Macro.t, state) :: Macro.t

  defp preprocess_template(ast, state) do
    Macro.postwalk ast, fn
      {name, meta, children} when not is_nil(children) ->
        eval_helpers {name, meta, children}, state
      x -> x
    end
  end

  defp eval_helpers({:base, _meta, children}, state) do
    arg = extract_arg children
    case arg do
      nil -> state.project_info.base_url
      path -> state.project_info.base_url <> path
    end
  end

  defp eval_helpers({:page, _meta, children}, state) do
    arg = extract_arg children
    state.project_info.base_url <> arg <> ".html"
  end

  defp eval_helpers({:post, _meta, children}, state) do
    arg = extract_arg children
    state.project_info.base_url <> "posts/" <> arg <> ".html"
  end

  defp eval_helpers({:asset, _meta, children}, state) do
    arg = extract_arg children
    state.project_info.base_url <> "assets/" <> arg
  end

  defp eval_helpers({:include, _meta, children}, state) do
    arg = extract_arg children
    case state.includes[arg] do
      nil ->
        warn "There is no includable named `#{arg}'."
        ""
      stub when is_binary(stub) -> stub
    end
  end

  defp eval_helpers({x, y, z}, _) do
    {x, y, z}
  end

  @spec extract_arg(Macro.t) :: [term]

  defp extract_arg(children) do
    children |> Code.eval_quoted |> elem(0) |> List.first
  end
end
