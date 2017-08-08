defmodule SiteBuilderTest do
  use ExUnit.Case, async: true
  alias Serum.ProjectInfo
  alias Serum.SiteBuilder

  setup_all do
    pid = spawn_link __MODULE__, :looper, []
    on_exit fn -> send pid, :stop end
    {:ok, [null_io: pid]}
  end

  test "starting and stopping" do
    Process.flag :trap_exit, true
    {:ok, pid} = SiteBuilder.start_link "", ""
    assert Process.alive? pid

    # Stop a SiteBuilder process and check if all subprocesses are dead.
    :ok = SiteBuilder.stop pid
    receive do
      {:EXIT, ^pid, :normal} -> refute Process.alive? pid
    after
      5000 -> flunk "SiteBuilder did not shut down after 5 seconds"
    end
  end

  describe "load_info/1" do
    test "ok", %{null_io: null} do
      {:ok, pid} = SiteBuilder.start_link "#{priv()}/testsite_good/", ""
      Process.group_leader pid, null
      expected =
        {:ok,
         %ProjectInfo{
           site_name: "New Website",
           site_description: "Welcome to my website!", preview_length: 200,
           date_format: "{WDfull}, {D} {Mshort} {YYYY}",
           base_url: "/test_base/", author: "Somebody",
           author_email: "somebody@example.com", list_title_all: "ALL POSTS",
           list_title_tag: "POSTS TAGGED ~s"
         }}
      assert expected == SiteBuilder.load_info pid
      SiteBuilder.stop pid
    end

    test "serum.json does not exist", %{null_io: null} do
      {:ok, pid} = SiteBuilder.start_link "/nonexistent_123/", ""
      Process.group_leader pid, null
      expected =
        {:error, {:enoent, "/nonexistent_123/serum.json", 0}}
      assert expected == SiteBuilder.load_info pid
      SiteBuilder.stop pid
    end

    test "contains json parse error", %{null_io: null} do
      path = "#{priv()}/test_projinfo/badjson/"
      {:ok, pid} = SiteBuilder.start_link path, ""
      Process.group_leader pid, null
      expected =
        {:error, {"parse error at position 0", path <> "serum.json", 0}}
      assert expected == SiteBuilder.load_info pid
      SiteBuilder.stop pid
    end

    test "contains json parse error 2", %{null_io: null} do
      path = "#{priv()}/test_projinfo/badjson_info/"
      {:ok, pid} = SiteBuilder.start_link path, ""
      Process.group_leader pid, null
      expected =
        {:error,
         {"parse error near `}' at position 25", path <> "serum.json", 0}}
      assert expected == SiteBuilder.load_info pid
      SiteBuilder.stop pid
    end

    test "contains validation error", %{null_io: null} do
      path = "#{priv()}/test_projinfo/schema_error/"
      {:ok, pid} = SiteBuilder.start_link path, ""
      Process.group_leader pid, null
      {:error, {:validate_json, errors}} = SiteBuilder.load_info pid
      Enum.each errors, fn {:error, {_msg, schema_name, 0}} ->
        assert "serum.json" == schema_name
      end
      SiteBuilder.stop pid
    end
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
