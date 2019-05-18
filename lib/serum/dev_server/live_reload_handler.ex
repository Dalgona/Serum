defmodule Serum.DevServer.LiveReloadHandler do
  @moduledoc false

  _moduledocp = """
  A Cowboy Websocket handler that sends signals to clients on file events.
  """

  @behaviour :cowboy_websocket

  require Serum.Util
  import Serum.Util
  alias Serum.DevServer.Service

  @impl true
  def init(req, state) do
    {:cowboy_websocket, req, state, %{idle_timeout: :infinity}}
  end

  @impl true
  def websocket_init(state) do
    warn("Live Reloader: WebSocket connected.")
    Service.GenServer.subscribe()

    {:ok, state}
  end

  @impl true
  def websocket_handle(message, state) do
    warn("Live Reloader: Ignoring a message from client: #{inspect(message)}")

    {:ok, state}
  end

  @impl true
  def websocket_info(message, state)

  def websocket_info(:send_reload, state) do
    {:reply, {:text, "reload"}, state}
  end

  def websocket_info(_, state), do: {:ok, state}

  @impl true
  def terminate(_reason, _mini_req, _state) do
    warn("Live Reloader: WebSocket disconnected.")

    :ok
  end
end
