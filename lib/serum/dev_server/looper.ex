defmodule Serum.DevServer.Looper do
  @moduledoc """
  A looper which accepts user inputs as server commands and processes them.
  """

  import Serum.Util
  alias Serum.DevServer.Service

  @doc "Starts the infinite command prompt loop."
  @spec looper() :: no_return()
  def looper do
    IO.write("#{Service.port()}> ")
    command = "" |> IO.gets() |> String.trim()

    run_command(command, [Service.site_dir()])
    looper()
  end

  @spec run_command(binary(), list()) :: :ok | no_return()
  def run_command(command, args)
  def run_command("", _), do: :ok

  def run_command("help", _) do
    """
    Available commands are:
      help   Displays this help message
      build  Rebuilds the project
      quit   Stops the server and quit
    """
    |> IO.write()
  end

  def run_command("build", _) do
    Service.rebuild()
  end

  def run_command("quit", [site_dir]) do
    IO.puts("Removing temporary directory \"#{site_dir}\"...")
    File.rm_rf!(site_dir)
    IO.puts("Shutting down...")
    System.halt(0)
  end

  def run_command(_, _) do
    warn("Type \"help\" for the list of available commands.")
  end
end
