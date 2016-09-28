defmodule Serum.DevServer.Looper do
  alias Serum.DevServer.Service

  def start_link() do
    Service.ensure_started
    pid = spawn_link fn -> looper end
    {:ok, pid}
  end

  defp looper() do
    cmd = IO.gets("#{Service.port}> ") |> String.trim
    case cmd do
      "help"  -> cmd :help
      "build" -> cmd :build
      "quit"  -> cmd :quit, Service.site_dir
      ""      -> looper
      _       ->
        IO.puts "Type `help` for the list of available commands."
        looper
    end
  end

  defp cmd(:help) do
    IO.puts "Available commands are:"
    IO.puts "  help   Displays this help message"
    IO.puts "  build  Rebuilds the project"
    IO.puts "  quit   Stops the server and quit"
    looper
  end

  defp cmd(:build) do
    Service.rebuild
    looper
  end

  defp cmd(:quit, site) do
    IO.puts "Removing temporary directory `#{site}`..."
    File.rm_rf! site
    IO.puts "Shutting down..."
    System.halt 0
  end
end
