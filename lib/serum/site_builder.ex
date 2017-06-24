defmodule Serum.SiteBuilder do
  @moduledoc """
  This GenServer acts as the main interface between the Serum command-line
  interface and internal site building logic. All tasks regarding building a
  Serum project must be done through this GenServer.
  """

  use GenServer
  alias Serum.Error
  alias Serum.Build
  alias Serum.ProjectInfo
  alias Serum.Validation

  #
  # GenServer Implementation - Client
  #

  @doc """
  Starts `Serum.SiteBuilder` GenServer

  `src` argument must be the path of the project directory (which holds
  `serum.json` file).

  `dest` argument is the path of the valid output directory. Its validity must
  be checked by its caller (i.e. the command-line interface).
  """
  @spec start_link(binary, binary) :: {:ok, pid}

  def start_link(src, dest) do
    src = String.ends_with?(src, "/") && src || src <> "/"
    dest = dest || src <> "site/"
    dest = String.ends_with?(dest, "/") && dest || dest <> "/"
    GenServer.start_link __MODULE__, {src, dest}
  end

  @doc """
  Loads `serum.json` file.

  Returns `{:ok, proj}` where `proj` is a `Serum.PostInfo` object parsed from
  `serum.json` file.

  Returns an error object otherwise.
  """
  @spec load_info(pid) :: Error.result(ProjectInfo.t)

  def load_info(server) do
    GenServer.call server, :load_info
  end

  @doc """
  Builds the loaded project.

  `mode` can be either `:parallel` or `:sequential`. This determines whether
  the site builder should launch the sub tasks parallelly or sequentially.

  If the whole build process succeeds, it prints the elapsed build time and
  returns `{:ok, dest}` where `dest` is the output directory.

  Returns an error object if the project metadata is not loaded (i.e.
  `load_info/1` is not called yet), or other error occurs.
  """
  @spec build(pid, Build.mode) :: Error.result(binary)

  def build(server, mode) do
    {time, result} =
      :timer.tc fn ->
        GenServer.call server, {:build, mode}
      end
    case result do
      {:ok, dest} ->
        IO.puts "Build process took #{time/1000}ms."
        {:ok, dest}
      {:error, _, _} = error -> error
    end
  end

  @doc """
  Stops the `Serum.SiteBuilder` GenServer.
  """
  @spec stop(pid) :: :ok

  def stop(server) do
    GenServer.cast server, :stop
  end

  #
  # GenServer Implementation - Server
  #

  @doc false

  def init({src, dest}) do
    {:ok, %{src: src, dest: dest, project_info: nil}}
  end

  @doc false

  def handle_call(msg, from, state)

  def handle_call(:load_info, _from, state) do
    case do_load_info state.src do
      {:ok, proj} ->
        {:reply, {:ok, proj}, Map.put(state, :project_info, proj)}
      {:error, _, _} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:build, _mode}, _from, state = %{project_info: nil}) do
    {:reply,
     {:error, :build_error, "project metadata is not loaded"},
     state}
  end

  def handle_call({:build, mode}, _from, state) do
    case Build.build mode, state do
      {:ok, new_state} ->
        {:reply, {:ok, new_state.dest}, new_state}
      {:error, _, _} = error ->
        {:reply, error, state}
    end
  end

  @doc false

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
