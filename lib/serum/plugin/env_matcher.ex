defmodule Serum.Plugin.EnvMatcher do
  @moduledoc false

  _moduledocp = """
  Provides a function to check whether to load the given plugin by
  checking the Mix environment.
  """

  alias Serum.Plugin

  @spec env_matches?(Plugin.spec()) :: boolean()
  def env_matches?(plugin_spec)
  def env_matches?(module) when is_atom(module), do: true

  def env_matches?({module, opts}) when is_atom(module) and is_list(opts) do
    current_env = Mix.env()

    case opts[:only] do
      nil -> true
      env when is_atom(env) -> current_env === env
      envs when is_list(envs) -> current_env in envs
      _ -> false
    end
  end
end
