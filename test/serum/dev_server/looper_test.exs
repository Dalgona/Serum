defmodule Serum.DevServer.LooperTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Serum.DevServer.Looper, only: [run_command: 1]
  alias Serum.DevServer.Service

  @commands ~w(build help quit)

  setup do
    uniq = Base.url_encode64(:crypto.strong_rand_bytes(6))
    src = Path.expand("serum_test_" <> uniq, System.tmp_dir!())
    site = Path.join(src, "site")
    child = %{id: Service, start: {Service.Mock, :start_link, [src, site]}}

    File.mkdir_p!(src)
    File.mkdir_p!(site)
    start_supervised!(child)

    on_exit(fn ->
      File.rm_rf!(src)
      File.rm_rf!(site)
    end)

    {:ok, site: site}
  end

  describe "run_command/1" do
    test "handles 'build' command" do
      stderr = capture_io(:stderr, fn -> send(self(), run_command("build")) end)

      assert String.trim(stderr) === ""
      assert_received true
    end

    test "handles 'help' command" do
      stdout = capture_io(fn -> send(self(), run_command("help")) end)

      Enum.each(@commands, &assert(String.contains?(stdout, &1)))
      assert_received true
    end

    test "handles 'quit' command", %{site: site} do
      assert File.exists?(site)

      capture_io(fn -> send(self(), run_command("quit")) end)

      refute File.exists?(site)
      assert_received false
    end

    test "discards any leading and trailing whitespaces" do
      out1 = capture_io(fn -> run_command("help") end)
      out2 = capture_io(fn -> run_command("  help") end)
      out3 = capture_io(fn -> run_command("help  ") end)
      out4 = capture_io(fn -> run_command("  help  ") end)

      assert 1 === [out1, out2, out3, out4] |> Enum.uniq() |> length()
    end

    test "quits on EOF", %{site: site} do
      assert File.exists?(site)

      capture_io(fn -> send(self(), run_command(:eof)) end)

      refute File.exists?(site)
      assert_received false
    end

    test "prints an error to stderr on any other inputs" do
      stderr = capture_io(:stderr, fn -> send(self(), run_command("x")) end)

      refute String.trim(stderr) === ""
      assert_received true
    end
  end
end
