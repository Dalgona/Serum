defmodule Serum.DevServer do
  alias Serum.DevServer.DirStatus

  def run(dir, port) do
    import Supervisor.Spec

    dir = String.ends_with?(dir, "/") && dir || dir <> "/"
    uniq = Base.url_encode64 <<:erlang.monotonic_time::size(64)>>, padding: false
    site = "/tmp/serum_" <> uniq

    if not File.exists? "#{dir}serum.json" do
      IO.puts "[31mError: `#{dir}serum.json` not found."
      IO.puts "Make sure you point at a valid Serum project directory.[0m"
    else
      DirStatus.start_link
      %{base_url: base} = "#{dir}serum.json"
                          |> File.read!
                          |> Poison.decode!(keys: :atoms)

      Serum.Build.build dir, site, :parallel

      children = [
        worker(__MODULE__, [dir, site, base, port], function: :start_server, id: "devserver_http"),
        worker(__MODULE__, [dir], function: :start_watcher, id: "devserver_fs")
      ]

      opts = [strategy: :one_for_one, name: Serum.DevServer.Supervisor]
      Supervisor.start_link children, opts

      looper {port, dir, site}
    end
  end

  def start_server(dir, site, base, port) do
    routes = [
      {"/[...]", Serum.DevServer.Handler, [dir: dir, site: site, base: base]}
    ]
    dispatch = :cowboy_router.compile [{:_, routes}]
    opts = [port: port]
    env = [dispatch: dispatch]
    ret = {:ok, _pid} = :cowboy.start_http Serum.DevServer.Http, 100, opts, env: env

    IO.puts "Server started listening on port #{port}."
    IO.puts "Type [1mhelp[0m for the list of available commands.\n"
    ret
  end

  def start_watcher(dir) do
    pid = spawn_link fn ->
      :fs.start_link :watcher, dir
      :fs.subscribe :watcher
      watcher_looper
    end
    {:ok, pid}
  end

  defp watcher_looper() do
    receive do
      {_pid, {:fs, :file_event}, {_path, _events}} ->
        DirStatus.set_dirty
        watcher_looper
      _ ->
        watcher_looper
    end
  end

  defp looper(state) do
    {port, src, site} = state
    cmd = IO.gets("#{port}> ") |> String.trim
    case cmd do
      "help"  -> cmd :help, state
      "build" -> cmd :build, src, site, state
      "quit"  -> cmd :quit, site
      _       -> looper state
    end
  end

  defp cmd(:help, state) do
    IO.puts "Available commands are:"
    IO.puts "  help   Displays this help message"
    IO.puts "  build  Rebuilds the project"
    IO.puts "  quit   Stops the server and quit"
    looper state
  end

  defp cmd(:quit, site) do
    IO.puts "Stopping server..."
    :ok = :cowboy.stop_listener Serum.DevServer.Http
    :ok = Supervisor.stop Serum.DevServer.Supervisor
    IO.puts "Removing temporary directory `#{site}`..."
    File.rm_rf! site
    :quit
  end

  defp cmd(:build, src, site, state) do
    Serum.Build.build src, site, :parallel
    looper state
  end
end
