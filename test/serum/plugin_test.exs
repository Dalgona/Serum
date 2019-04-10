defmodule Serum.PluginTest do
  use ExUnit.Case
  import Serum.Plugin

  priv_dir = :serum |> :code.priv_dir() |> IO.iodata_to_binary()

  1..3
  |> Enum.map(&Path.join(priv_dir, "test_plugins/dummy_plugin_#{&1}.ex"))
  |> Enum.each(&Code.require_file/1)

  test "load_plugins/1" do
    {:ok, loaded_plugins} =
      load_plugins([Serum.DummyPlugin1, Serum.DummyPlugin2, Serum.DummyPlugin3])

    assert length(loaded_plugins) == 3

    agent_state = Agent.get(Serum.Plugin, & &1)

    count =
      Enum.reduce(agent_state, 0, fn {_, plugins}, acc ->
        acc + length(plugins)
      end)

    assert count == 27
  end
end
