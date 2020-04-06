defmodule Serum.Plugin do
  @moduledoc """
  A behaviour that all Serum plugin module must implement.

  This module allows experienced Serum users and developers to make their own
  Serum plugins which can extend the functionality of Serum.

  ## For Plugin Users

  To enable Serum plugins, add a `plugins` key to your `serum.exs`(if it does
  not exist), and put names of Serum plugin modules there.

      %{
        plugins: [
          Awesome.Serum.Plugin,
          Great.Serum.Plugin
        ]
      }

  You can also restrict some plugins to run only in specific Mix environments.
  For example, if plugins are configured like the code below, only
  `Awesome.Serum.Plugin` plugin will be loaded when `MIX_ENV` is set to `prod`.

      %{
        plugins: [
          Awesome.Serum.Plugin,
          {Great.Serum.Plugin, only: :dev},
          {Another.Serum.Plugin, only: [:dev, :test]}
        ]
      }

  The order of plugins is important, as Serum will call plugins one by one,
  from the first item to the last one. Therefore these two configurations below
  may produce different results.

  Configuration 1:

      %{
        plugins: [
          Awesome.Serum.Plugin,
          Another.Serum.Plugin
        ]
      }

  Configuration 2:

      %{
        plugins: [
          Another.Serum.Plugin,
          Awesome.Serum.Plugin
        ]
      }
  """

  use Agent
  require Serum.V2.Result, as: Result
  import Serum.V2.Console, only: [put_msg: 2]
  alias Serum.Plugin.Loader
  alias Serum.Plugin.State

  defstruct [:module, :name, :version, :description, :implements, :args]

  @type t :: %__MODULE__{
          module: atom(),
          name: binary(),
          version: binary(),
          description: binary(),
          implements: [atom()],
          args: term()
        }

  @type spec :: atom() | {atom(), plugin_options()}
  @type plugin_options :: [only: atom() | [atom()], args: term()]

  @doc false
  @spec start_link(any()) :: Agent.on_start()
  def start_link(_) do
    Agent.start_link(fn -> %State{} end, name: __MODULE__)
  end

  @doc false
  @spec load_plugins([spec()]) :: Result.t([t()])
  def load_plugins(plugin_specs), do: Loader.load_plugins(plugin_specs)

  @doc false
  @spec show_info([t()]) :: Result.t({})
  def show_info(plugins)
  def show_info([]), do: Result.return()

  def show_info(plugins) do
    Enum.each(plugins, fn p ->
      msg = [
        :bright,
        p.name,
        " v",
        to_string(p.version),
        :reset,
        " (#{module_name(p.module)})\n",
        :light_black,
        p.description
      ]

      put_msg(:plugin, msg)
    end)

    Result.return()
  end

  @spec module_name(atom()) :: binary()
  defp module_name(module) do
    module |> to_string() |> String.replace_prefix("Elixir.", "")
  end
end
