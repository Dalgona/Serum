defmodule Serum.DevServer.PromptTest do
  use ExUnit.Case
  import ExUnit.CaptureIO
  import Mox
  import Serum.DevServer.Prompt
  import Serum.TestHelper
  alias Serum.DevServer.Service
  alias Serum.GlobalBindings
  alias Serum.IOProxy

  @commands ~w(build help open quit)

  setup_all do
    {:ok, io_opts} = IOProxy.config()

    IOProxy.config(mute_err: false)
    GlobalBindings.load(%{site: %{base_url: "/test-site/"}})

    on_exit(fn ->
      IOProxy.config(Keyword.new(io_opts))
      GlobalBindings.load(%{})
    end)
  end

  setup do
    src = get_tmp_dir("serum_test_")
    site = Path.join(src, "site")
    sup_opts = [name: Serum.DevServer.Supervisor, strategy: :one_for_one]
    service = %{id: Service, start: {Service.Mock, :start_link, [src, site]}}

    supervisor = %{
      id: Serum.DevServer.Supervisor,
      type: :supervisor,
      start: {Supervisor, :start_link, [[service], sup_opts]}
    }

    File.mkdir_p!(src)
    File.mkdir_p!(site)
    start_supervised!(supervisor)

    on_exit(fn ->
      File.rm_rf!(src)
      File.rm_rf!(site)
    end)

    {:ok, site: site}
  end

  describe "start/1" do
    test "enters the command line interface" do
      capture_io("help\ndetach\n", fn ->
        send(self(), start(allow_detach: true))
      end)

      assert_received {:ok, :detached}
    end

    test "fails if the server is not running" do
      Supervisor.stop(Serum.DevServer.Supervisor)

      assert {:error, :noproc} === start()
    end
  end

  describe "run_command/1" do
    test "handles 'build' command" do
      stderr =
        capture_io(:stderr, fn ->
          send(self(), run_command("build", %{}))
        end)

      assert String.trim(stderr) === ""
      assert_received :ok
    end

    test "handles 'help' command (detach enabled)" do
      stdout =
        capture_io(fn ->
          send(self(), run_command("help", %{allow_detach: true}))
        end)

      Enum.each(@commands, &assert(String.contains?(stdout, &1)))
      assert String.contains?(stdout, "detach")
      assert_received :ok
    end

    test "handles 'help' command (detach disabled)" do
      stdout =
        capture_io(fn ->
          send(self(), run_command("help", %{allow_detach: false}))
        end)

      Enum.each(@commands, &assert(String.contains?(stdout, &1)))
      refute String.contains?(stdout, "detach")
      assert_received :ok
    end

    test "handles 'detach' command (detach enabled)" do
      assert :detach === run_command("detach", %{allow_detach: true})
    end

    test "handles 'detach' command (detach disabled)" do
      stderr =
        capture_io(:stderr, fn ->
          run_command("detach", %{allow_detach: false})
        end)

      refute "" === String.trim(stderr)
    end

    test "handles 'open' command" do
      Serum.DevServer.CommandHandler.Mock
      |> expect(:open_url, fn "http://localhost:8080/test-site/" -> :ok end)

      stderr =
        capture_io(:stderr, fn ->
          send(self(), run_command("open", %{}))
        end)

      assert String.trim(stderr) === ""
      assert_received :ok
    end

    test "prints a warning when failed to open a browser" do
      Serum.DevServer.CommandHandler.Mock
      |> expect(:open_url, fn "http://localhost:8080/test-site/" -> :error end)

      stderr =
        capture_io(:stderr, fn ->
          send(self(), run_command("open", %{}))
        end)

      assert stderr =~ "not supported"
      assert_received :ok
    end

    test "handles 'quit' command", %{site: site} do
      assert File.exists?(site)

      capture_io(fn -> send(self(), run_command("quit", %{})) end)

      refute File.exists?(site)
      assert_received :quit
    end

    test "discards any leading and trailing whitespaces" do
      options = %{allow_detach: false}
      out1 = capture_io(fn -> run_command("help", options) end)
      out2 = capture_io(fn -> run_command("  help", options) end)
      out3 = capture_io(fn -> run_command("help  ", options) end)
      out4 = capture_io(fn -> run_command("  help  ", options) end)

      assert 1 === [out1, out2, out3, out4] |> Enum.uniq() |> length()
    end

    test "quits on EOF", %{site: site} do
      assert File.exists?(site)

      capture_io(fn -> send(self(), run_command(:eof, %{})) end)

      refute File.exists?(site)
      assert_received :quit
    end

    test "prints an error to stderr on any other inputs" do
      stderr =
        capture_io(:stderr, fn ->
          send(self(), run_command("x", %{}))
        end)

      refute String.trim(stderr) === ""
      assert_received {:ok, _}
    end
  end
end
