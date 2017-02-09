defmodule Serum.ProjectInfoStorage do
  @moduledoc """
  This module implements a GenServer which keeps a ProjectInfo struct as its
  state and provides access to the project metadata during build processes.
  """

  use GenServer
  import Serum.Util
  alias Serum.ProjectInfo

  #
  # GenServer Implementation - Client
  #

  defmacro name(owner) do
    quote do
      {:via, Registry, {Serum.Registry, {:project_info, unquote(owner)}}}
    end
  end

  @spec start_link(pid) :: {:ok, pid}

  def start_link(owner) do
    case Process.whereis __MODULE__ do
      nil ->
        GenServer.start_link __MODULE__, [], name: name(owner)
      running when is_pid(running) ->
        {:ok, running}
    end
  end

  @spec load(pid, ProjectInfo.t) :: :ok

  def load(owner, proj) do
    GenServer.call name(owner), {:load, proj}
  end

  @spec get(pid, atom) :: term

  def get(owner, key) do
    GenServer.call name(owner), {:get, key}
  end

  @spec all(pid) :: map

  def all(owner) do
    GenServer.call name(owner), :all
  end

  #
  # GenServer Implementation - Server
  #

  def init(_state) do
    Process.flag :trap_exit, true
    {:ok, nil}
  end

  def handle_call({:load, proj}, _from, _state) do
    {:reply, :ok, proj}
  end

  def handle_call({:get, _key}, _from, nil) do
    warn "project info is not loaded yet"
    {:reply, nil, nil}
  end

  def handle_call({:get, key}, _from, proj) do
    {:reply, Map.get(proj, key), proj}
  end

  def handle_call(:all, _from, proj) do
    {:reply, proj, proj}
  end
end
