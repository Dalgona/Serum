defmodule Serum.DevServer.Service do
  @moduledoc """
  A GenServer that provides some utility functions while the Serum development
  server is running.
  """

  use GenServer

  ## Client

  @spec start_link(String.t, String.t, pos_integer)
    :: {:ok, pid}
    |  {:error, atom}
  def start_link(dir, site, port) do
    GenServer.start_link __MODULE__, [dir, site, port], name: __MODULE__
  end

  @spec rebuild() :: :ok
  def rebuild() do
    GenServer.call __MODULE__, :rebuild
  end

  ## Server

  def init([dir, site, port]) do
    {:ok, {dir, site, port}}
  end

  def handle_call(:rebuild, _from, state) do
    {dir, site, _} = state
    case Serum.Build.build(dir, site, :parallel) do
      {:ok, _} -> :ok
      error = {:error, _, _} ->
        Serum.Error.show(error)
        IO.puts "\x1b[33mError occurred while building the website."
        IO.puts "The website may not be displayed correctly.\x1b[0m"
    end
    {:reply, :ok, state}
  end
end
