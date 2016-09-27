defmodule Serum.DevServer.DirStatus do
  use GenServer

  # Client
  def start_link, do: GenServer.start_link __MODULE__, false, name: __MODULE__

  def is_dirty, do: GenServer.call __MODULE__, :is_dirty

  def set_dirty, do: GenServer.cast __MODULE__, :set_dirty

  # Server (callbacks)
  def handle_call(:is_dirty, _from, state), do: {:reply, state, false}

  def handle_cast(:set_dirty, _state), do: {:noreply, true}
end
