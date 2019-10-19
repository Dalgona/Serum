defmodule Serum.Plugin.Loader do
  @moduledoc false

  _moduledocp = "A module for loading Serum plugins from serum.exs."

  import Serum.IOProxy
  alias Serum.Plugin
  alias Serum.Result

  @serum_version Version.parse!(Mix.Project.config()[:version])
  @elixir_version Version.parse!(System.version())
  @required_msg "You must implement this callback, or the plugin may fail."

  @spec load_plugins([Plugin.spec()]) :: Result.t([Plugin.t()])
  def load_plugins(modules) do
    modules
    |> Stream.filter(&env_matches?/1)
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

  @spec env_matches?(Plugin.spec()) :: boolean()
  defp env_matches?(plugin_spec)
  defp env_matches?(mod) when is_atom(mod), do: true

  defp env_matches?({mod, only: env}) when is_atom(mod) and is_atom(env) do
    Mix.env() == env
  end

  defp env_matches?({mod, only: envs}) when is_atom(mod) and is_list(envs) do
    Mix.env() in envs
  end

  defp env_matches?(_), do: false

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
      implements: module.implements()
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
