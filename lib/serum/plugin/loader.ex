defmodule Serum.Plugin.Loader do
  @moduledoc false

  _moduledocp = "A module for loading Serum plugins from serum.exs."

  import Serum.IOProxy
  alias Serum.Plugin
  alias Serum.Plugin.EnvMatcher
  alias Serum.Result

  @serum_version Version.parse!(Mix.Project.config()[:version])
  @elixir_version Version.parse!(System.version())

  @old_callback_arities %{
    build_started: 2,
    reading_pages: 1,
    reading_posts: 1,
    reading_templates: 1,
    processing_page: 1,
    processing_post: 1,
    processing_template: 1,
    processed_page: 1,
    processed_post: 1,
    processed_template: 1,
    processed_list: 1,
    processed_pages: 1,
    processed_posts: 1,
    rendering_fragment: 2,
    rendered_fragment: 1,
    rendered_page: 1,
    wrote_file: 1,
    build_succeeded: 2,
    build_failed: 3,
    finalizing: 2
  }

  @spec load_plugins([Plugin.spec()]) :: Result.t([Plugin.t()])
  def load_plugins(modules) do
    modules
    |> Stream.filter(&EnvMatcher.env_matches?/1)
    |> Stream.map(&from_spec/1)
    |> Stream.uniq()
    |> Enum.map(&make_plugin/1)
    |> Result.aggregate_values(:load_plugins)
    |> case do
      {:ok, plugins} ->
        update_agent(plugins)

        {:ok, plugins}

      {:error, _} = error ->
        error
    end
  end

  @spec from_spec(Plugin.spec()) :: atom()
  defp from_spec(plugin_spec)
  defp from_spec({mod, _}), do: mod
  defp from_spec(x), do: x

  @spec make_plugin(atom()) :: Result.t(Plugin.t())
  defp make_plugin(module) do
    name = module.name()
    version = Version.parse!(module.version())
    elixir = module.elixir()
    serum = module.serum()

    validate_elixir_version(name, elixir)
    validate_serum_version(name, serum)

    plugin = %Plugin{
      module: module,
      name: name,
      version: version,
      description: module.description(),
      implements: normalized_implements(module)
    }

    {:ok, plugin}
  rescue
    exception ->
      ex_name = module_name(exception.__struct__)
      ex_msg = Exception.message(exception)
      msg = "#{ex_name} while loading plugin (module: #{module}): #{ex_msg}"

      {:error, msg}
  end

  @spec validate_elixir_version(binary(), Version.requirement()) :: :ok
  defp validate_elixir_version(name, requirement) do
    if Version.match?(@elixir_version, requirement) do
      :ok
    else
      msg =
        "The plugin \"#{name}\" is not compatible with " <>
          "the current version of Elixir(#{@elixir_version}). " <>
          "This plugin may not work as intended."

      put_err(:warn, msg)
    end
  end

  @spec validate_serum_version(binary(), Version.requirement()) :: :ok
  defp validate_serum_version(name, requirement) do
    if Version.match?(@serum_version, requirement) do
      :ok
    else
      msg =
        "The plugin \"#{name}\" is not compatible with " <>
          "the current version of Serum(#{@serum_version}). " <>
          "This plugin may not work as intended."

      put_err(:warn, msg)
    end
  end

  @spec normalized_implements(module()) :: [{atom(), integer()}]
  defp normalized_implements(module) do
    Enum.map(module.implements(), fn
      fun when is_atom(fun) -> {fun, @old_callback_arities[fun] || 0}
      {fun, arity} when is_atom(fun) and is_integer(arity) -> {fun, arity}
    end)
  end

  @spec update_agent([Plugin.t()]) :: :ok
  defp update_agent(plugins) do
    Agent.update(Plugin, fn _ -> %{} end)

    plugins
    |> Enum.map(fn plugin -> Enum.map(plugin.implements, &{&1, plugin}) end)
    |> List.flatten()
    |> Enum.each(fn {fun, plugin} ->
      Agent.update(Plugin, fn state ->
        Map.put(state, fun, [plugin | state[fun] || []])
      end)
    end)

    Agent.update(Plugin, fn state ->
      for {key, value} <- state, into: %{}, do: {key, Enum.reverse(value)}
    end)
  end

  @spec module_name(atom()) :: binary()
  defp module_name(module) do
    module |> to_string() |> String.replace_prefix("Elixir.", "")
  end
end
