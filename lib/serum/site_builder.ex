defmodule Serum.SiteBuilder do
  @moduledoc """
  This GenServer acts as the main interface between the Serum command-line
  interface and internal site building logic. All tasks regarding building a
  Serum project must be done through this GenServer.
  """

  use GenServer
  alias Serum.Result
  alias Serum.Build
  alias Serum.ProjectInfo

  #
  # Client Functions
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
    dest = dest || Path.join(src, "site")
    GenServer.start_link(__MODULE__, {src, dest})
  end

  @doc """
  Loads `serum.json` file.

  Returns `{:ok, proj}` where `proj` is a `Serum.PostInfo` object parsed from
  `serum.json` file.

  Returns an error object otherwise.
  """
  @spec load_info(pid) :: Result.t(ProjectInfo.t())

  def load_info(server) do
    GenServer.call(server, :load_info)
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
  @spec build(pid, Build.mode()) :: Result.t(binary)

  def build(server, mode) do
    {time, result} =
      :timer.tc(fn ->
        GenServer.call(server, {:build, mode})
      end)

    case result do
      {:ok, dest} ->
        IO.puts("Build process took #{time / 1000}ms.")
        {:ok, dest}

      {:error, _} = error ->
        error
    end
  end

  @doc """
  Stops the `Serum.SiteBuilder` GenServer.
  """
  @spec stop(pid) :: :ok

  def stop(server) do
    GenServer.cast(server, :stop)
  end

  #
  # GenServer Callbacks
  #

  def init({src, dest}) do
    {:ok, %{src: src, dest: dest, project_info: nil}}
  end

  def handle_call(msg, from, state)

  def handle_call(:load_info, _from, state) do
    case ProjectInfo.load(state.src, state.dest) do
      {:ok, proj} ->
        {:reply, {:ok, proj}, %{state | project_info: proj}}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  def handle_call({:build, _mode}, _from, state = %{project_info: nil}) do
    {:reply, {:error, "project metadata is not loaded"}, state}
  end

  def handle_call({:build, mode}, _from, state) do
    case Build.build(mode, state.project_info) do
      {:ok, dest} -> {:reply, {:ok, dest}, state}
      {:error, _} = error -> {:reply, error, state}
    end
  end

  def handle_cast(:stop, _state) do
    exit(:normal)
  end
end
