defmodule Serum.DevServer.Service do
  @moduledoc """
  A GenServer that provides some utility functions while the Serum development
  server is running.
  """

  use GenServer

  def ensure_started() do
    case GenServer.whereis __MODULE__ do
      nil -> ensure_started
      _   -> :ok
    end
  end

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

  @spec source_dir() :: String.t
  def source_dir(),
    do: GenServer.call __MODULE__, :source_dir

  @spec site_dir() :: String.t
  def site_dir(),
    do: GenServer.call __MODULE__, :site_dir

  @spec port() :: pos_integer
  def port(),
    do: GenServer.call __MODULE__, :port

  @spec log(integer, String.t, String.t, String.t) :: any
  def log(code, from, method, path) do
    GenServer.cast __MODULE__, {:log, code, from, method, path}
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

  def handle_call(:source_dir, _from, state), do: {:reply, elem(state, 0), state}
  def handle_call(:site_dir, _from, state),   do: {:reply, elem(state, 1), state}
  def handle_call(:port, _from, state),       do: {:reply, elem(state, 2), state}

  def handle_cast({:log, 200, from, method, path}, state) do
    IO.puts "\x1b[32m[200]\x1b[0m #{from} #{method} \x1b[1m#{path}\x1b[0m"
    {:noreply, state}
  end

  def handle_cast({:log, 404, from, method, path}, state) do
    IO.puts "\x1b[31m[404]\x1b[0m #{from} #{method} \x1b[1m#{path}\x1b[0m"
    {:noreply, state}
  end

  def handle_cast({:log, code, from, method, path}, state) do
    IO.puts "[#{code}] #{from} #{method} \x1b[1m#{path}\x1b[0m"
    {:noreply, state}
  end
end
