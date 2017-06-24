defmodule Serum.DevServer.Service do
  @moduledoc """
  A GenServer that provides some utility functions while the Serum development
  server is running.
  """

  use GenServer
  import Serum.Util
  alias Serum.Error
  alias Serum.SiteBuilder

  #
  # GenServer Implementation - Client
  #

  @doc "Starts `Serum.DevServer.Service` GenServer."
  @spec start_link(pid, binary, binary, pos_integer)
    :: {:ok, pid} | {:error, atom}

  def start_link(builder, dir, site, portnum) do
    args = [builder, dir, site, portnum]
    GenServer.start_link __MODULE__, args, name: __MODULE__
  end

  @doc "Rebuilds the current Serum project."
  @spec rebuild() :: :ok

  def rebuild(), do: GenServer.call __MODULE__, :rebuild

  @doc "Returns the source directory."
  @spec source_dir() :: binary

  def source_dir(), do: GenServer.call __MODULE__, :source_dir

  @doc "Returns the output directory (under `/tmp`)."
  @spec site_dir() :: binary

  def site_dir(), do: GenServer.call __MODULE__, :site_dir

  @doc "Returns the port number the server currently listening on."
  @spec port() :: pos_integer

  def port(), do: GenServer.call __MODULE__, :port

  #
  # GenServer Implementation - Server
  #

  @doc false

  def init([builder, dir, site, portnum]) do
    do_rebuild builder
    {:ok, {builder, dir, site, portnum}}
  end

  @doc false

  def handle_call(msg, from, state)

  def handle_call(:rebuild, _from, state) do
    {builder, _, _, _} = state
    do_rebuild builder
    {:reply, :ok, state}
  end

  def handle_call(:source_dir, _from, state),
    do: {:reply, elem(state, 1), state}

  def handle_call(:site_dir, _from, state),
    do: {:reply, elem(state, 2), state}

  def handle_call(:port, _from, state),
    do: {:reply, elem(state, 3), state}

  @spec do_rebuild(pid) :: :ok

  defp do_rebuild(builder) do
    with {:ok, _info} <- SiteBuilder.load_info(builder),
         {:ok, _} <- SiteBuilder.build(builder, :parallel)
    do
      :ok
    else
      {:error, _, _} = error -> build_failed error
    end
  end

  defp build_failed(error) do
    Error.show error
    warn "Error occurred while building the website."
    warn "The website may not be displayed correctly."
  end
end
