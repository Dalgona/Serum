defmodule Serum.DevServer.Service.GenServerTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Serum.TestHelper
  alias Serum.DevServer
  alias Serum.DevServer.Service.GenServer, as: GS
  alias Serum.V2.Console

  # IMPORTANT NOTE: PLEASE MAKE SURE THE TCP PORT 8080 IS NOT IN USE
  #                 BEFORE RUNNING THIS TEST.

  setup_all do
    tmp_dir = get_tmp_dir("serum_test_")
    pid = start_supervised!(%{id: :ignore_io, start: {StringIO, :open, [""]}})
    test_sup! = hd(Process.info(self())[:links])
    old_group_leader! = Process.info(test_sup!)[:group_leader]
    {:ok, io_config} = Console.config()

    make_project(tmp_dir)
    Process.group_leader(test_sup!, pid)
    start_supervised!(%{id: :dev_server, start: {DevServer, :run, [tmp_dir, 8080]}})
    Process.group_leader(test_sup!, old_group_leader!)
    Console.config(mute_err: false)
    on_exit(fn -> Console.config(Keyword.new(io_config)) end)

    {:ok, tmp_dir: tmp_dir}
  end

  test "if source_dir/0 returns the source directory", %{tmp_dir: tmp_dir} do
    assert tmp_dir === GS.source_dir()
  end

  test "if site_dir/0 returns the temp output directory" do
    assert String.contains?(GS.site_dir(), "serum_")
  end

  test "if port/0 returns the current port" do
    assert 8080 === GS.port()
  end

  test "if dirty?/0 returns the current file system status" do
    assert is_boolean(GS.dirty?())
  end

  test "if subscribe/0 adds the calling process to its subscriber state" do
    GS.subscribe()

    pid = self()
    state = :sys.get_state(GS)

    assert Enum.any?(state.subscribers, fn {_, v} -> v === pid end)
  end

  test "if rebuild/0 successfully builds the project" do
    err = capture_io(:stderr, fn -> GS.rebuild() end)

    assert "" === String.trim(err)
  end

  test "if a build process initiated by rebuild/0 may fail", ctx do
    dir = ctx.tmp_dir

    File.rename(Path.join(dir, "serum.exs"), Path.join(dir, "serum.exs_"))

    err = capture_io(:stderr, fn -> GS.rebuild() end)

    assert "" !== String.trim(err)
    File.rename(Path.join(dir, "serum.exs_"), Path.join(dir, "serum.exs"))
  end
end
