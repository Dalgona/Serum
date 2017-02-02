defmodule Serum.SiteBuilder do
  use GenServer
  alias Serum.Error
  alias Serum.BuildDataStorage
  alias Serum.PostInfoStorage
  alias Serum.ProjectInfoStorage
  alias Serum.TagStorage

  @type build_mode :: :sequential | :parallel

  #
  # GenServer Implementation - Client
  #

  @spec start_link(String.t, String.t) :: {:ok, pid}

  def start_link(src, dest) do
    src = String.ends_with?(src, "/") && src || src <> "/"
    dest = dest || src <> "site/"
    dest = String.ends_with?(dest, "/") && dest || dest <> "/"
    GenServer.start_link __MODULE__, {src, dest}
  end

  @spec load_info(pid) :: :ok

  def load_info(server) do
    GenServer.call server, :load_info
  end

  # TODO: @spec
  @spec build(pid, build_mode) :: Error.result(String.t)

  def build(server, mode) do
    GenServer.call server, {:build, mode}
  end

  @spec stop(pid) :: :ok

  def stop(server) do
    GenServer.cast server, :stop
  end

  #
  # GenServer Implementation - Server
  #

  @storage_agents [BuildDataStorage, PostInfoStorage, TagStorage]

  def init(state) do
    ProjectInfoStorage.start_link self()
    for mod <- @storage_agents, do: mod.start_link self()
    {:ok, state}
  end

  def handle_call(:load_info, _from, {src, dest}) do
    result = Serum.Build.Preparation.load_info src
    {:reply, result, {src, dest}}
  end

  def handle_call({:build, mode}, _from, {src, dest}) do
    result = Serum.Build.build src, dest, mode
    {:reply, result, {src, dest}}
  end

  def handle_cast(:stop, _state) do
    for mod <- @storage_agents, do: mod.stop self()
    exit :normal
  end
end
