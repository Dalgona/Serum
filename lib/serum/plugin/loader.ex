defmodule Serum.Plugin.Loader do
  @moduledoc false

  _moduledocp = "A module for loading Serum plugins from serum.exs."

  require Serum.ForeignCode, as: ForeignCode
  require Serum.V2.Result, as: Result
  alias Serum.Plugin
  alias Serum.Plugin.State

  @typep init_state :: {module(), term()}

  @msg_load_failed "failed to load plugins:"

  @spec load([term()]) :: Result.t([Plugin.t()])
  def load(maybe_specs) do
    Result.run do
      specs <- normalize_specs(maybe_specs)
      specs = filter_specs(specs)
      plugins <- make_plugins(specs)
      init_states <- init_plugins(plugins)
      update_agent(plugins, init_states)

      Result.return(plugins)
    end
  end

  @spec normalize_specs([term()]) :: Result.t([Plugin.spec()])
  defp normalize_specs(maybe_specs) do
    maybe_specs
    |> Enum.map(&normalize_spec/1)
    |> Result.aggregate(@msg_load_failed)
  end

  @spec normalize_spec(term()) :: Result.t(Plugin.spec())
  defp normalize_spec(maybe_spec)
  defp normalize_spec(module) when is_atom(module), do: Result.return({module, []})

  defp normalize_spec({module, opts}) when is_atom(module) and is_list(opts) do
    if Keyword.keyword?(opts) do
      Result.return({module, opts})
    else
      message = "expected the second tuple element to be a keyword list, got: #{inspect(opts)}"

      Result.fail(Simple: [message])
    end
  end

  defp normalize_spec(x) do
    Result.fail(Simple: ["#{inspect(x)} is not a valid Serum plugin specification"])
  end

  @spec filter_specs([Plugin.spec()]) :: [Plugin.spec()]
  defp filter_specs(specs) do
    specs
    |> Enum.filter(&env_matches?/1)
    |> Enum.uniq_by(&elem(&1, 0))
  end

  @spec env_matches?(Plugin.spec()) :: boolean()
  def env_matches?({module, opts}) when is_atom(module) and is_list(opts) do
    current_env = Mix.env()

    case opts[:only] do
      nil -> true
      env when is_atom(env) -> current_env === env
      envs when is_list(envs) -> current_env in envs
      _ -> false
    end
  end

  @spec make_plugins([Plugin.spec()]) :: Result.t([Plugin.t()])
  defp make_plugins(specs) do
    specs
    |> Enum.map(&make_plugin/1)
    |> Result.aggregate(@msg_load_failed)
  end

  @spec make_plugin(Plugin.spec()) :: Result.t(Plugin.t())
  defp make_plugin({module, opts}) do
    Result.return(%Plugin{
      module: module,
      name: module.name(),
      version: Version.parse!(module.version()),
      description: module.description(),
      implements: module.implements(),
      args: opts[:args]
    })
  rescue
    exception -> Result.fail(Exception: [exception, __STACKTRACE__])
  end

  @spec init_plugins([Plugin.t()]) :: Result.t([init_state()])
  defp init_plugins(plugins) do
    plugins
    |> Enum.map(&init_plugin/1)
    |> Result.aggregate(@msg_load_failed)
  end

  @spec init_plugin(Plugin.t()) :: Result.t(init_state())
  defp init_plugin(%Plugin{module: module, args: args}) do
    ForeignCode.call module.init(args) do
      state -> Result.return({module, state})
    end
  end

  @spec update_agent([Plugin.t()], [init_state()]) :: Result.t({})
  defp update_agent(plugins, init_states) do
    map =
      plugins
      |> Enum.map(fn plugin ->
        Enum.map(plugin.implements, &Tuple.insert_at(&1, 2, plugin))
      end)
      |> List.flatten()
      |> Enum.group_by(&elem(&1, 0), &Tuple.delete_at(&1, 0))
      |> Map.new()

    Agent.update(Plugin, fn _ -> %State{states: Map.new(init_states), callbacks: map} end)
    Result.return()
  end
end
