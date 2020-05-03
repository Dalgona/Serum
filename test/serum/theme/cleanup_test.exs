defmodule Serum.Theme.CleanupTest do
  use Serum.Case
  require Serum.V2.Result, as: Result
  import ExUnit.CaptureIO
  alias Serum.Theme
  alias Serum.Theme.Loader
  alias Serum.Theme.Cleanup
  alias Serum.V2.Console

  @init_state {nil, nil}

  setup_all do
    {:ok, console_config} = Console.config()
    {:ok, _} = Console.config(mute_msg: false, mute_err: false)

    on_exit(fn -> Console.config(Keyword.new(console_config)) end)
  end

  setup do: on_exit(fn -> Agent.update(Theme, fn _ -> {nil, nil} end) end)

  describe "cleanup_theme/0" do
    test "calls cleanup/1 callback and resets the agent" do
      {:ok, pid} = Agent.start_link(fn -> false end)
      theme_mock = get_theme_mock(%{cleanup: fn _ -> dummy_cleanup(pid) end})
      {:ok, %Theme{}} = Loader.load_theme(theme_mock)

      assert {:ok, _} = Cleanup.cleanup_theme()
      assert Agent.get(pid, & &1)
      assert Agent.get(Theme, & &1) === @init_state

      :ok = Agent.stop(pid)
    end

    test "prints a warning when cleanup/1 callback failed" do
      theme_mock = get_theme_mock(%{cleanup: &failing_cleanup/1})
      {:ok, %Theme{}} = Loader.load_theme(theme_mock)

      stderr =
        capture_io(:stderr, fn ->
          assert {:ok, _} = Cleanup.cleanup_theme()
        end)

      assert stderr =~ "cleanup"
      assert Agent.get(Theme, & &1) === @init_state
    end

    test "prints a warning when cleanup/1 callback returned an unexpected value" do
      theme_mock = get_theme_mock(%{cleanup: &weird_cleanup/1})
      {:ok, %Theme{}} = Loader.load_theme(theme_mock)

      stderr =
        capture_io(:stderr, fn ->
          assert {:ok, _} = Cleanup.cleanup_theme()
        end)

      assert stderr =~ "123"
      assert Agent.get(Theme, & &1) === @init_state
    end

    test "prints a warning when cleanup/1 callback raised an error" do
      theme_mock = get_theme_mock(%{cleanup: &raising_cleanup/1})
      {:ok, %Theme{}} = Loader.load_theme(theme_mock)

      stderr =
        capture_io(:stderr, fn ->
          assert {:ok, _} = Cleanup.cleanup_theme()
        end)

      assert stderr =~ "RuntimeError"
      assert Agent.get(Theme, & &1) === @init_state
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
