defmodule Serum.SiteBuilder do
  use GenServer
  alias Serum.Error
  alias Serum.Build
  alias Serum.BuildDataStorage
  alias Serum.PostInfoStorage
  alias Serum.ProjectInfo
  alias Serum.ProjectInfoStorage
  alias Serum.TagStorage
  alias Serum.Validation

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
    result = do_load_info src
    {:reply, result, {src, dest}}
  end

  def handle_call({:build, mode}, _from, {src, dest}) do
    result = Build.build src, dest, mode
    {:reply, result, {src, dest}}
  end

  def handle_cast(:stop, _state) do
    for mod <- @storage_agents, do: mod.stop self()
    exit :normal
  end

  #
  # Internal Functions
  #

  @spec do_load_info(String.t) :: Error.result

  defp do_load_info(dir) do
    path = dir <> "serum.json"
    IO.puts "Reading project metadata `#{path}'..."
    case File.read path do
      {:ok, data} -> decode_json path, data
      {:error, reason} ->
        {:error, :file_error, {reason, path, 0}}
    end
  end

  @spec decode_json(String.t, String.t) :: Error.result

  defp decode_json(path, data) do
    case Poison.decode data do
      {:ok, proj} -> validate proj
      {:error, :invalid, pos} ->
        {:error, :json_error,
         {"parse error at position #{pos}", path, 0}}
      {:error, {:invalid, token, pos}} ->
        {:error, :json_error,
         {"parse error near `#{token}' at position #{pos}", path, 0}}
    end
  end

  @spec validate(map) :: Error.result

  defp validate(proj) do
    owner = self()
    Validation.load_schema owner
    case Validation.validate owner, "serum.json", proj do
      :ok -> ProjectInfoStorage.load(owner, ProjectInfo.new(proj))
      error -> error
    end
  end
end
