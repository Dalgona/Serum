defmodule Serum.DevServer do
  @moduledoc """
  This module provides functions for starting the Serum development server.
  """

  import Serum.Util
  alias Serum.DevServer.Service

  @spec run(dir :: String.t, port :: pos_integer) :: any
  def run(dir, port) do
    import Supervisor.Spec

    dir = String.ends_with?(dir, "/") && dir || dir <> "/"
    uniq = Base.url_encode64 <<System.monotonic_time::size(64)>>, padding: false
    site = "/tmp/serum_" <> uniq

    if not File.exists? "#{dir}serum.json" do
      IO.puts "\x1b[31mError: `#{dir}serum.json` not found."
      IO.puts "Make sure you point at a valid Serum project directory.\x1b[0m"
    else
      %{base_url: base} = "#{dir}serum.json"
                          |> File.read!
                          |> Poison.decode!(keys: :atoms)

      children = [
        worker(Microscope, [site, base, port, [Microscope.Logger]]),
        worker(Serum.DevServer.Service, [dir, site, port])
      ]

      opts = [strategy: :one_for_one, name: Serum.DevServer.Supervisor]
      Supervisor.start_link children, opts

      Service.rebuild

      looper {port, site}
    end
  end

  defp looper(state) do
    {port, site} = state
    cmd = "#{port}> " |> IO.gets |> String.trim
    case cmd do
      "help"  -> cmd :help, state
      "build" -> cmd :build, state
      "quit"  -> cmd :quit, site
      ""      -> looper state
      _       ->
        warn("Type `help` for the list of available commands.")
        looper state
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
    IO.puts "Removing temporary directory `#{site}`..."
    File.rm_rf! site
    IO.puts "Stopping server..."
    :quit
  end

  defp cmd(:build, state) do
    Service.rebuild
    looper state
  end
end
