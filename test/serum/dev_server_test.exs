defmodule Serum.DevServerTest do
  use ExUnit.Case, async: false
  require Serum.TestHelper
  import Serum.TestHelper
  alias Serum.DevServer

  # IMPORTANT NOTE: PLEASE MAKE SURE THE TCP PORT 8080 IS NOT IN USE
  #                 BEFORE RUNNING THIS TEST.

  setup_all do
    tmp_dir = get_tmp_dir("serum_test_")

    ["" | ~w(assets media pages posts includes templates)]
    |> Enum.map(&Path.join(tmp_dir, &1))
    |> Enum.each(&File.mkdir_p!/1)

    on_exit(fn -> File.rm_rf!(tmp_dir) end)
    File.cp!(fixture("proj/good/serum.exs"), Path.join(tmp_dir, "serum.exs"))

    ~w(base list page post)
    |> Enum.map(&["templates/", &1, ".html.eex"])
    |> Enum.each(fn name ->
      File.cp!(fixture(name), Path.join(tmp_dir, name))
    end)

    File.cp!(fixture("templates/nav.html.eex"), Path.join(tmp_dir, "includes/nav.html.eex"))

    pid = start_supervised!(%{id: :ignore_io, start: {__MODULE__, :ignore_io, []}})

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

      {:ok, sock} = :gen_tcp.listen(8080, [])
      assert {:error, msg} = DevServer.run(ctx.tmp_dir, 8080)
      assert String.contains?(msg, "8080")
      :ok = :gen_tcp.close(sock)
    end
  end

  def ignore_io, do: {:ok, spawn_link(&ignore_io_loop/0)}

  defp ignore_io_loop do
    receive do
      {:io_request, from, reply_as, _request} ->
        send(from, {:io_reply, reply_as, :ok})
    end

    ignore_io_loop()
  end
end
