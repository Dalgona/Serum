defmodule Serum.Plugin.Client do
  @moduledoc false

  _moduledocp = "Provides functions to call callbacks of loaded plugins."

  # For interface/2 macro
  require Serum.Plugin.Client.Macros
  require Serum.Result, as: Result
  import Serum.Plugin.Client.Macros
  alias Serum.Error
  alias Serum.Error.ExceptionMessage
  alias Serum.Error.SimpleMessage
  alias Serum.Fragment
  alias Serum.Page
  alias Serum.Plugin
  alias Serum.Post
  alias Serum.PostList
  alias Serum.Template

  interface :action, build_started(src :: binary(), dest :: binary()) :: Result.t({})
  interface :function, reading_pages(files :: [binary()]) :: Result.t([binary()])
  interface :function, reading_posts(files :: [binary()]) :: Result.t([binary()])
  interface :function, reading_templates(files :: [binary()]) :: Result.t([binary()])
  interface :function, processing_page(file :: Serum.File.t()) :: Result.t(Serum.File.t())
  interface :function, processing_post(file :: Serum.File.t()) :: Result.t(Serum.File.t())
  interface :function, processing_template(file :: Serum.File.t()) :: Result.t(Serum.File.t())
  interface :function, processed_page(page :: Page.t()) :: Result.t(Page.t())
  interface :function, processed_post(post :: Post.t()) :: Result.t(Post.t())
  interface :function, processed_template(template :: Template.t()) :: Result.t(Template.t())
  interface :function, processed_list(list :: PostList.t()) :: Result.t(PostList.t())
  interface :function, processed_pages(pages :: [Page.t()]) :: Result.t([Page.t()])
  interface :function, processed_posts(posts :: [Post.t()]) :: Result.t([Post.t()])

  interface :function,
            rendering_fragment(html :: Floki.html_tree(), metadata :: map()) ::
              Result.t(Floki.html_tree())

  interface :function, rendered_fragment(frag :: Fragment.t()) :: Result.t(Fragment.t())
  interface :function, rendered_page(file :: Serum.File.t()) :: Result.t(Serum.File.t())
  interface :action, wrote_file(file :: Serum.File.t()) :: Result.t({})
  interface :action, build_succeeded(src :: binary(), dest :: binary()) :: Result.t({})

  interface :action,
            build_failed(src :: binary(), dest :: binary(), result :: Result.t(term)) ::
              Result.t({})

  interface :action, finalizing(src :: binary(), dest :: binary()) :: Result.t({})

  @spec call_action(atom(), [term()]) :: Result.t({})
  defp call_action(fun, args) do
    Plugin
    |> Agent.get(&(&1[fun] || []))
    |> do_call_action(fun, args)
  end

  @spec do_call_action([{integer(), Plugin.t()}], atom(), [term()]) :: Result.t({})
  defp do_call_action(arity_and_plugins, fun, args)
  defp do_call_action([], _fun, _args), do: Result.return()

  defp do_call_action([{_arity, plugin} | arity_and_plugins], fun, args) do
    new_args = args ++ [plugin.args]

    case apply(plugin.module, fun, new_args) do
      {:ok, _} ->
        do_call_action(arity_and_plugins, fun, args)

      {:error, %Error{}} = error ->
        error

      term ->
        message =
          "#{module_name(plugin.module)}.#{fun} returned " <>
            "an unexpected value: #{inspect(term)}"

        {:error, %Error{message: %SimpleMessage{text: message}, caused_by: []}}
    end
  rescue
    exception ->
      {:error,
       %Error{
         message: %ExceptionMessage{exception: exception, stacktrace: __STACKTRACE__},
         caused_by: []
       }}
  end

  @spec call_function(atom(), [a | term()]) :: Result.t(a) when a: term()
  def call_function(fun, [arg | args]) do
    Plugin
    |> Agent.get(&(&1[fun] || []))
    |> do_call_function(fun, args, arg)
  end

  @spec do_call_function([{integer, Plugin.t()}], atom(), [term()], a) :: Result.t(a)
        when a: term()
  defp do_call_function(arity_and_plugins, fun, args, acc)
  defp do_call_function([], _fun, _args, acc), do: {:ok, acc}

  defp do_call_function([{_arity, plugin} | arity_and_plugins], fun, args, acc) do
    new_args = [acc | args] ++ [plugin.args]

    case apply(plugin.module, fun, new_args) do
      {:ok, new_acc} ->
        do_call_function(arity_and_plugins, fun, args, new_acc)

      {:error, %Error{}} = error ->
        error

      term ->
        message =
          "#{module_name(plugin.module)}.#{fun} returned " <>
            "an unexpected value: #{inspect(term)}"

        {:error, %Error{message: %SimpleMessage{text: message}, caused_by: []}}
    end
  rescue
    exception ->
      {:error,
       %Error{
         message: %ExceptionMessage{exception: exception, stacktrace: __STACKTRACE__},
         caused_by: []
       }}
  end

  @spec module_name(atom()) :: binary()
  defp module_name(module) do
    module |> to_string() |> String.replace_prefix("Elixir.", "")
  end
end
