defmodule Serum.Plugin.LoaderTest do
  use ExUnit.Case
  require Serum.TestHelper
  import ExUnit.CaptureIO
  import Serum.Plugin.Loader
  import Serum.TestHelper, only: :macros
  alias Serum.IOProxy
  alias Serum.Plugin

  "plugins/*plugin*.ex"
  |> fixture()
  |> Path.wildcard()
  |> Enum.each(&Code.require_file/1)

  setup_all do
    {:ok, io_opts} = IOProxy.config()

    IOProxy.config(mute_err: false, mute_msg: false)
    on_exit(fn -> IOProxy.config(Keyword.new(io_opts)) end)
  end

  setup do
    on_exit(fn -> Agent.update(Plugin, fn _ -> %{} end) end)
  end

  describe "load_plugins/1" do
    test "always loads plugins without :only option" do
      plugin_specs = [Serum.DummyPlugin1, {Serum.DummyPlugin2, []}]

      {:ok, loaded_plugins} = load_plugins(plugin_specs)

      assert length(loaded_plugins) === 2

      agent_state = Agent.get(Serum.Plugin, & &1)

      count =
        Enum.reduce(agent_state, 0, fn {_, plugins}, acc ->
          acc + length(plugins)
        end)

      assert count == 18
    end

    test "loads plugins only with matching Mix environment" do
      plugin_specs = [
        Serum.DummyPlugin1,
        {Serum.DummyPlugin2, only: :prod},
        {Serum.DummyPlugin3, only: [:dev, :test]}
      ]

      {:ok, loaded_plugins} = load_plugins(plugin_specs)
      loaded_modules = Enum.map(loaded_plugins, & &1.module)

      assert length(loaded_plugins) === 2
      assert Serum.DummyPlugin2 not in loaded_modules
    end

    test "prints warning when loading an incompatible plugin" do
      output =
        capture_io(:stderr, fn ->
          {:ok, loaded_plugins} = load_plugins([Serum.IncompatiblePlugin])

          send(self(), loaded_plugins)
        end)

      receive do
        loaded_plugins ->
          assert length(loaded_plugins) === 1
          assert output =~ "not compatible"
      end
    end

    test "returns an error when an invalid plugin spec was given" do
      plugin_specs = [
        Serum.DummyPlugin1,
        123,
        {Serum.DummyPlugin2},
        {Serum.DummyPlugin3, only: :dev}
      ]

      assert {:error, {_, errors}} = load_plugins(plugin_specs)
      assert length(errors) === 2
    end

    test "returns an error when the plugin fails to load" do
      {:error, {_, [error | _]}} = load_plugins([Serum.FailingPlugin2])
      {:error, message} = error

      assert message =~ "RuntimeError"
      assert message =~ "test: version"
    end
  end
end
