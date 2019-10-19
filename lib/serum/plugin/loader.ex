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
    |> Stream.uniq_by(fn
      module when is_atom(module) -> module
      {module, _} when is_atom(module) -> module
    end)
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

  @spec make_plugin(Plugin.spec()) :: Result.t(Plugin.t())
  defp make_plugin(plugin_spec)
  defp make_plugin(mod) when is_atom(mod), do: do_make_plugin(mod, nil)

  defp make_plugin({mod, opts}) when is_atom(mod) and is_list(opts) do
    do_make_plugin(mod, opts[:args])
  end

  @spec do_make_plugin(atom(), term()) :: Result.t(Plugin.t())
  defp do_make_plugin(module, args) do
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
      implements: normalized_implements(module),
      args: args
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
    map =
      plugins
      |> Enum.map(fn plugin ->
        Enum.map(plugin.implements, &Tuple.insert_at(&1, 2, plugin))
      end)
      |> List.flatten()
      |> Enum.group_by(&elem(&1, 0), &Tuple.delete_at(&1, 0))
      |> Map.new()

    Agent.update(Plugin, fn _ -> map end)
  end

  @spec module_name(atom()) :: binary()
  defp module_name(module) do
    module |> to_string() |> String.replace_prefix("Elixir.", "")
  end
end
