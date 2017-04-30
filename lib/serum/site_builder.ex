defmodule Serum.SiteBuilder do
  use GenServer
  alias Serum.Error
  alias Serum.Build
  alias Serum.ProjectInfo
  alias Serum.Validation

  #
  # GenServer Implementation - Client
  #

  @spec start_link(binary, binary) :: {:ok, pid}

  def start_link(src, dest) do
    src = String.ends_with?(src, "/") && src || src <> "/"
    dest = dest || src <> "site/"
    dest = String.ends_with?(dest, "/") && dest || dest <> "/"
    GenServer.start_link __MODULE__, {src, dest}
  end

  @spec load_info(pid) :: Error.result(ProjectInfo.t)

  def load_info(server) do
    GenServer.call server, :load_info
  end

  @spec build(pid, Build.mode) :: Error.result(binary)

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

  def init({src, dest}) do
    {:ok, {src, dest, nil}}
  end

  def handle_call(:load_info, _from, {src, dest, _}) do
    case do_load_info src do
      {:ok, proj} ->
        {:reply, {:ok, proj}, {src, dest, proj}}
      {:error, _, _} = error ->
        {:reply, error, {src, dest, nil}}
    end
  end

  def handle_call({:build, _mode}, _from, {src, dest, nil}) do
    {:reply,
     {:error, :build_error, "project metadata is not loaded"},
     {src, dest, nil}}
  end

  def handle_call({:build, mode}, _from, {src, dest, proj}) do
    state = %{project_info: proj, build_data: %{}, src: src, dest: dest}
    result = Build.build mode, state
    {:reply, result, {src, dest, proj}}
  end

  def handle_cast(:stop, _state) do
    exit :normal
  end

  #
  # Internal Functions
  #

  @spec do_load_info(binary) :: Error.result(ProjectInfo.t)

  defp do_load_info(dir) do
    path = dir <> "serum.json"
    IO.puts "Reading project metadata `#{path}'..."
    case File.read path do
      {:ok, data} -> decode_json path, data
      {:error, reason} ->
        {:error, :file_error, {reason, path, 0}}
    end
  end

  @spec decode_json(binary, binary) :: Error.result(ProjectInfo.t)

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

  @spec validate(map) :: Error.result(ProjectInfo.t)

  defp validate(proj) do
    case Validation.validate "serum.json", proj do
      :ok -> {:ok, ProjectInfo.new(proj)}
      error -> error
    end
  end
end
