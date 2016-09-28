defmodule Serum.DevServer.Service do
  use GenServer

  ## Client

  def start_link(dir, site, port) do
    GenServer.start_link __MODULE__, [dir, site, port], name: __MODULE__
  end

  def rebuild() do
    GenServer.call __MODULE__, :rebuild
  end

  def log(code, from, method, path) do
    GenServer.cast __MODULE__, {:log, code, from, method, path}
  end

  ## Server

  def init([dir, site, port]) do
    {:ok, {dir, site, port}}
  end

  def handle_call(:rebuild, _from, state) do
    {dir, site, _} = state
    {:ok, _} = Serum.Build.build dir, site, :parallel
    {:reply, :ok, state}
  end

  def handle_cast({:log, 200, from, method, path}, state) do
    IO.puts "\x1b[32m[200]\x1b[0m #{from} #{method} \x1b[1m#{path}\x1b[0m"
    {:noreply, state}
  end

  def handle_cast({:log, 404, from, method, path}, state) do
    IO.puts "\x1b[32m[404]\x1b[0m #{from} #{method} \x1b[1m#{path}\x1b[0m"
    {:noreply, state}
  end

  def handle_cast({:log, code, from, method, path}, state) do
    IO.puts "[#{code}] #{from} #{method} \x1b[1m#{path}\x1b[0m"
    {:noreply, state}
  end
end
