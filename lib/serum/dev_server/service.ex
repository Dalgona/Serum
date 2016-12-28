defmodule Serum.DevServer.Service do
  @moduledoc """
  A GenServer that provides some utility functions while the Serum development
  server is running.
  """

  use GenServer
  alias Serum.Build
  alias Serum.Error

  ## Client

  @spec start_link(String.t, String.t, pos_integer)
    :: {:ok, pid} | {:error, atom}
  def start_link(dir, site, portnum) do
    GenServer.start_link __MODULE__, [dir, site, portnum], name: __MODULE__
  end

  @spec rebuild() :: :ok
  def rebuild(), do: GenServer.call __MODULE__, :rebuild

  @spec source_dir() :: String.t
  def source_dir(), do: GenServer.call __MODULE__, :source_dir

  @spec site_dir() :: String.t
  def site_dir(), do: GenServer.call __MODULE__, :site_dir

  @spec port() :: pos_integer
  def port(), do: GenServer.call __MODULE__, :port

  ## Server

  def init([dir, site, portnum]) do
    do_rebuild dir, site
    {:ok, {dir, site, portnum}}
  end

  def handle_call(:rebuild, _from, state) do
    {dir, site, _} = state
    do_rebuild dir, site
    {:reply, :ok, state}
  end

  def handle_call(:source_dir, _from, state),
    do: {:reply, elem(state, 0), state}

  def handle_call(:site_dir, _from, state),
    do: {:reply, elem(state, 1), state}

  def handle_call(:port, _from, state),
    do: {:reply, elem(state, 2), state}

  @spec do_rebuild(String.t, String.t) :: Error.result
  defp do_rebuild(dir, site) do
    case Build.build dir, site, :parallel do
      {:ok, _} -> :ok
      error = {:error, _, _} ->
        Error.show error
        IO.puts "\x1b[33mError occurred while building the website."
        IO.puts "The website may not be displayed correctly.\x1b[0m"
    end
  end
end
