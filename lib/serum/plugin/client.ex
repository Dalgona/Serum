defmodule Serum.Plugin.Client do
  @moduledoc false

  _moduledocp = "Provides functions to call callbacks of loaded plugins."

  # For interface/2 macro
  require Serum.Plugin.Client.Macros
  require Serum.V2.Result, as: Result
  import Serum.Plugin.Client.Macros
  alias Serum.Plugin
  alias Serum.Project
  alias Serum.V2
  alias Serum.V2.Error
  alias Serum.V2.Fragment
  alias Serum.V2.Page
  alias Serum.V2.Post
  alias Serum.V2.PostList
  alias Serum.V2.Template

  interface :action, build_started(project :: Project.t()) :: Result.t({})
  interface :action, build_succeeded(project :: Project.t()) :: Result.t({})
  interface :action, build_failed(project :: Project.t(), result :: Result.t()) :: Result.t({})

  interface :function, reading_pages(paths :: [binary()]) :: Result.t([binary()])
  interface :function, reading_posts(paths :: [binary()]) :: Result.t([binary()])
  interface :function, reading_templates(paths :: [binary()]) :: Result.t([binary()])

  interface :function, processing_pages(files :: [V2.File.t()]) :: Result.t([V2.File.t()])
  interface :function, processing_posts(files :: [V2.File.t()]) :: Result.t([V2.File.t()])
  interface :function, processing_templates(files :: [V2.File.t()]) :: Result.t([V2.File.t()])

  interface :function, processed_pages(pages :: [Page.t()]) :: Result.t([Page.t()])
  interface :function, processed_posts(posts :: [Post.t()]) :: Result.t([Post.t()])

  interface :function,
            processed_templates(templates :: [Template.t()]) :: Result.t([Template.t()])

  interface :function,
            generated_post_lists(post_lists :: [[PostList.t()]]) :: Result.t([[PostList.t()]])

  interface :function,
            generating_fragment(html_tree :: Floki.html_tree(), metadata :: map()) ::
              Result.t(Floki.html_tree())

  interface :function, generated_fragment(fragment :: Fragment.t()) :: Result.t(Fragment.t())
  interface :function, rendered_pages(files :: [V2.File.t()]) :: Result.t([V2.File.t()])
  interface :action, wrote_files(files :: [V2.File.t()]) :: Result.t({})

  @spec call_action(atom(), [term()]) :: Result.t({})
  defp call_action(fun, args) do
    Plugin
    |> Agent.get(&(&1.callbacks[fun] || []))
    |> do_call_action(fun, args, Plugin.states())
    |> case do
      {:ok, new_states} ->
        Plugin.update_states(new_states)
        Result.return()

      {:error, %Error{}} = error ->
        error
    end
  end

  @spec do_call_action([{integer(), Plugin.t()}], atom(), [term()], map()) :: Result.t(map())
  defp do_call_action(arity_and_plugins, fun, args, states)
  defp do_call_action([], _fun, _args, states), do: Result.return(states)

  defp do_call_action([{_arity, plugin} | arity_and_plugins], fun, args, states) do
    new_args = args ++ [states[plugin.module]]
    fun_repr = "#{module_name(plugin.module)}.#{fun}"

    case apply(plugin.module, fun, new_args) do
      {:ok, new_state} ->
        new_states = Map.put(states, plugin.module, new_state)

        do_call_action(arity_and_plugins, fun, args, new_states)

      {:error, %Error{} = error} ->
        Result.fail(Simple: ["#{fun_repr} returned an error:"], caused_by: [error])

      term ->
        Result.fail(Simple: ["#{fun_repr} returned an unexpected value: #{inspect(term)}"])
    end
  rescue
    exception -> Result.fail(Exception: [exception, __STACKTRACE__])
  end

  @spec call_function(atom(), [a | term()]) :: Result.t(a) when a: term()
  def call_function(fun, [arg | args]) do
    Plugin
    |> Agent.get(&(&1.callbacks[fun] || []))
    |> do_call_function(fun, args, arg, Plugin.states())
    |> case do
      {:ok, {value, new_states}} ->
        Plugin.update_states(new_states)
        Result.return(value)

      {:error, %Error{}} = error ->
        error
    end
  end

  @spec do_call_function([{integer, Plugin.t()}], atom(), [term()], a, map()) ::
          Result.t({a, map()})
        when a: term()
  defp do_call_function(arity_and_plugins, fun, args, acc, states)
  defp do_call_function([], _fun, _args, acc, states), do: Result.return({acc, states})

  defp do_call_function([{_arity, plugin} | arity_and_plugins], fun, args, acc, states) do
    new_args = [acc | args] ++ [states[plugin.module]]
    fun_repr = "#{module_name(plugin.module)}.#{fun}"

    case apply(plugin.module, fun, new_args) do
      {:ok, {new_acc, new_state}} ->
        new_states = Map.put(states, plugin.module, new_state)

        do_call_function(arity_and_plugins, fun, args, new_acc, new_states)

      {:error, %Error{} = error} ->
        Result.fail(Simple: ["#{fun_repr} returned an error:"], caused_by: [error])

      term ->
        Result.fail(Simple: ["#{fun_repr} returned an unexpected value: #{inspect(term)}"])
    end
  rescue
    exception -> Result.fail(Exception: [exception, __STACKTRACE__])
  end

  @spec module_name(atom()) :: binary()
  defp module_name(module) do
    module |> to_string() |> String.replace_prefix("Elixir.", "")
  end
end
