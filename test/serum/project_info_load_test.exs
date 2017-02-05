defmodule ProjectInfoLoadTest do
  use ExUnit.Case, async: true
  import ExUnit.CaptureIO
  alias Serum.SiteBuilder
  alias Serum.ProjectInfoStorage

  test "get info when not loaded" do
    {:ok, pid} = SiteBuilder.start_link "", ""
    warn =
      capture_io :stderr, fn ->
        send self(), ProjectInfoStorage.get(pid, :site_name)
      end
    assert "\x1b[33m * project info is not loaded yet\x1b[0m\n" == warn
    assert_received nil
    SiteBuilder.stop pid
  end

  test "ok" do
    {:ok, pid} = SiteBuilder.start_link "#{priv()}/testsite_good/", ""
    assert :ok == SiteBuilder.load_info pid
    SiteBuilder.stop pid
  end

  test "serum.json does not exist" do
    {:ok, pid} = SiteBuilder.start_link "/nonexistent_123/", ""
    expected =
      {:error, :file_error, {:enoent, "/nonexistent_123/serum.json", 0}}
    assert expected == SiteBuilder.load_info pid
    SiteBuilder.stop pid
  end

  test "contains json parse error" do
    path = "#{priv()}/test_projinfo/badjson/"
    {:ok, pid} = SiteBuilder.start_link path, ""
    expected =
      {:error, :json_error,
       {"parse error at position 0", path <> "serum.json", 0}}
    assert expected == SiteBuilder.load_info pid
    SiteBuilder.stop pid
  end

  test "contains json parse error 2" do
    path = "#{priv()}/test_projinfo/badjson_info/"
    {:ok, pid} = SiteBuilder.start_link path, ""
    expected =
      {:error, :json_error,
       {"parse error near `}' at position 25", path <> "serum.json", 0}}
    assert expected == SiteBuilder.load_info pid
    SiteBuilder.stop pid
  end

  test "contains validation error" do
    path = "#{priv()}/test_projinfo/schema_error/"
    {:ok, pid} = SiteBuilder.start_link path, ""
    {:error, :child_tasks, {:validate_json, errors}} = SiteBuilder.load_info pid
    Enum.each errors, fn {:error, reason, {_msg, schema_name, 0}} ->
      assert :validation_error == reason
      assert "serum.json" == schema_name
    end
    SiteBuilder.stop pid
  end

  defp priv, do: :code.priv_dir :serum
end
