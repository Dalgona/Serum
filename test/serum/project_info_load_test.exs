defmodule ProjectInfoLoadTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  alias Serum.SiteBuilder
  alias Serum.ProjectInfoStorage

  setup_all do
    pid = spawn_link __MODULE__, :looper, []
    on_exit fn -> send pid, :stop end
    {:ok, [null_io: pid]}
  end

  test "get info when not loaded" do
    {:ok, pid} = SiteBuilder.start_link "", ""
    warn =
      capture_io :stderr, fn ->
        capture_io fn ->
          send self(), ProjectInfoStorage.get(pid, :site_name)
        end
      end
    assert "\x1b[33m * project info is not loaded yet\x1b[0m\n" == warn
    assert_received nil
    SiteBuilder.stop pid
  end

  test "ok", %{null_io: null} do
    {:ok, pid} = SiteBuilder.start_link "#{priv()}/testsite_good/", ""
    Process.group_leader pid, null
    assert :ok == SiteBuilder.load_info pid
    SiteBuilder.stop pid
  end

  test "serum.json does not exist", %{null_io: null} do
    {:ok, pid} = SiteBuilder.start_link "/nonexistent_123/", ""
    Process.group_leader pid, null
    expected =
      {:error, :file_error, {:enoent, "/nonexistent_123/serum.json", 0}}
    assert expected == SiteBuilder.load_info pid
    SiteBuilder.stop pid
  end

  test "contains json parse error", %{null_io: null} do
    path = "#{priv()}/test_projinfo/badjson/"
    {:ok, pid} = SiteBuilder.start_link path, ""
    Process.group_leader pid, null
    expected =
      {:error, :json_error,
       {"parse error at position 0", path <> "serum.json", 0}}
    assert expected == SiteBuilder.load_info pid
    SiteBuilder.stop pid
  end

  test "contains json parse error 2", %{null_io: null} do
    path = "#{priv()}/test_projinfo/badjson_info/"
    {:ok, pid} = SiteBuilder.start_link path, ""
    Process.group_leader pid, null
    expected =
      {:error, :json_error,
       {"parse error near `}' at position 25", path <> "serum.json", 0}}
    assert expected == SiteBuilder.load_info pid
    SiteBuilder.stop pid
  end

  test "contains validation error", %{null_io: null} do
    path = "#{priv()}/test_projinfo/schema_error/"
    {:ok, pid} = SiteBuilder.start_link path, ""
    Process.group_leader pid, null
    {:error, :child_tasks, {:validate_json, errors}} = SiteBuilder.load_info pid
    Enum.each errors, fn {:error, reason, {_msg, schema_name, 0}} ->
      assert :validation_error == reason
      assert "serum.json" == schema_name
    end
    SiteBuilder.stop pid
  end

  defp priv, do: :code.priv_dir :serum

  def looper do
    receive do
      {:io_request, from, reply_as, _} when is_pid(from) ->
        send from, {:io_reply, reply_as, :ok}
        looper()
      :stop -> :stop
      _ -> looper()
    end
  end
end
