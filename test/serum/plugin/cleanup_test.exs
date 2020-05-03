defmodule Serum.Plugin.CleanupTest do
  use Serum.Case
  require Serum.V2.Result, as: Result
  import ExUnit.CaptureIO
  alias Serum.Plugin
  alias Serum.Plugin.Cleanup
  alias Serum.Plugin.State
  alias Serum.V2.Console

  setup_all do
    {:ok, console_config} = Console.config()
    {:ok, _} = Console.config(mute_msg: false, mute_err: false)

    on_exit(fn -> Console.config(Keyword.new(console_config)) end)
  end

  setup do
    on_exit(fn -> Agent.update(Plugin, fn _ -> %State{} end) end)
  end

  describe "cleanup/0" do
    test "calls cleanup/1 callback for each plugin and resets the agent" do
      {:ok, pid} = Agent.start_link(fn -> false end)
      plugin_mock = get_plugin_mock(%{cleanup: fn _ -> dummy_cleanup(pid) end}, %{})
      {:ok, _} = Plugin.load([plugin_mock])

      assert {:ok, _} = Cleanup.cleanup()
      assert Agent.get(pid, & &1)
      assert Agent.get(Plugin, & &1) === %State{}

      :ok = Agent.stop(pid)
    end

    test "prints a warning when cleanup/1 callback failed" do
      plugin_mock = get_plugin_mock(%{cleanup: &failing_cleanup/1}, %{})
      {:ok, _} = Plugin.load([plugin_mock])

      stderr =
        capture_io(:stderr, fn ->
          assert {:ok, _} = Cleanup.cleanup()
        end)

      assert stderr =~ "cleanup"
      assert Agent.get(Plugin, & &1) === %State{}
    end

    test "prints a warning when cleanup/1 callback returned an unexpected value" do
      plugin_mock = get_plugin_mock(%{cleanup: &weird_cleanup/1}, %{})
      {:ok, _} = Plugin.load([plugin_mock])

      stderr =
        capture_io(:stderr, fn ->
          assert {:ok, _} = Cleanup.cleanup()
        end)

      assert stderr =~ "123"
      assert Agent.get(Plugin, & &1) === %State{}
    end

    test "prints a warning when cleanup/1 callback raised an error" do
      plugin_mock = get_plugin_mock(%{cleanup: &raising_cleanup/1}, %{})
      {:ok, _} = Plugin.load([plugin_mock])

      stderr =
        capture_io(:stderr, fn ->
          assert {:ok, _} = Cleanup.cleanup()
        end)

      assert stderr =~ "RuntimeError"
      assert Agent.get(Plugin, & &1) === %State{}
    end
  end

  defp dummy_cleanup(pid) do
    Agent.update(pid, fn _ -> true end)
    Result.return()
  end

  defp failing_cleanup(_), do: Result.fail(Simple: ["cleanup"])
  defp weird_cleanup(_), do: 123
  defp raising_cleanup(_), do: raise("cleanup")
end
