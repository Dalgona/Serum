defmodule Serum.DevServer.Looper do
  @moduledoc """
  A looper which accepts user inputs as server commands and processes them.
  """

  import Serum.Util
  alias Serum.DevServer.Service

  @spec start_link() :: {:ok, pid}
  def start_link() do
    pid = spawn_link fn -> looper() end
    {:ok, pid}
  end

  @spec looper() :: no_return
  defp looper() do
    IO.write "#{Service.port}> "
    cmd = "" |> IO.gets |> String.trim
    case cmd do
      "help"  -> cmd :help
      "build" -> cmd :build
      "quit"  -> cmd :quit, Service.site_dir
      ""      -> looper()
      _       ->
        warn "Type `help` for the list of available commands."
        looper()
    end
  end

  @spec cmd(atom) :: no_return
  @spec cmd(:quit, String.t) :: no_return
  defp cmd(:help) do
    IO.puts "Available commands are:"
    IO.puts "  help   Displays this help message"
    IO.puts "  build  Rebuilds the project"
    IO.puts "  quit   Stops the server and quit"
    looper()
  end

  defp cmd(:build) do
    Service.rebuild
    looper()
  end

  defp cmd(:quit, site) do
    IO.puts "Removing temporary directory `#{site}`..."
    File.rm_rf! site
    IO.puts "Shutting down..."
    System.halt 0
  end
end
