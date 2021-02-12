defmodule Serum.DevServerTest do
  use ExUnit.Case, async: false
  import Serum.TestHelper
  alias Serum.DevServer

  # IMPORTANT NOTE: PLEASE MAKE SURE THE TCP PORT 8080 IS NOT IN USE
  #                 BEFORE RUNNING THIS TEST.

  setup_all do
    tmp_dir = get_tmp_dir("serum_test_")
    pid = start_supervised!(%{id: :ignore_io, start: {StringIO, :open, [""]}})

    make_project(tmp_dir)

    {:ok, tmp_dir: tmp_dir, ignore_io: pid}
  end

  describe "run/2" do
    test "successfully starts the server", ctx do
      Process.group_leader(self(), ctx.ignore_io)

      assert {:ok, pid} = DevServer.run(ctx.tmp_dir, 8080)

      :ok = Supervisor.stop(pid)
    end

    test "fails to start the server due to the lack of serum.exs", ctx do
      dir = ctx.tmp_dir

      Process.group_leader(self(), ctx.ignore_io)
      File.rename(Path.join(dir, "serum.exs"), Path.join(dir, "serum.exs_"))
      assert {:error, {:enoent, _, 0}} = DevServer.run(dir, 8080)
      File.rename(Path.join(dir, "serum.exs_"), Path.join(dir, "serum.exs"))
    end

    test "fails to start the server due to EADDRINUSE", ctx do
      Process.flag(:trap_exit, true)
      Process.group_leader(self(), ctx.ignore_io)

      {result, sock} = :gen_tcp.listen(8080, [])
      assert {:error, msg} = DevServer.run(ctx.tmp_dir, 8080)
      assert String.contains?(msg, "8080")
      :ok = :gen_tcp.close(sock)
    end
  end
end
