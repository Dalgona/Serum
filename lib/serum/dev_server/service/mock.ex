defmodule Serum.DevServer.Service.Mock do
  @moduledoc false

  _moduledocp = """
  A fake implementation of `Serum.DevServer.Service` behaviour for testing.
  """

  use GenServer
  alias Serum.DevServer.Service

  @behaviour Service

  @doc false
  @spec start_link(binary(), binary()) :: {:ok, pid()} | {:error, term()}
  def start_link(src, site) do
    GenServer.start_link(__MODULE__, {src, site}, name: __MODULE__)
  end

  @impl Service
  @spec rebuild() :: :ok
  def rebuild, do: :ok

  @impl Service
  @spec source_dir() :: binary()
  def source_dir, do: GenServer.call(__MODULE__, :src)

  @impl Service
  @spec site_dir() :: binary()
  def site_dir, do: GenServer.call(__MODULE__, :site)

  @impl Service
  @spec port() :: pos_integer()
  def port, do: 8080

  @impl Service
  @spec dirty?() :: boolean()
  def dirty?, do: false

  @impl Service
  @spec subscribe() :: :ok
  def subscribe, do: :ok

  @impl GenServer
  def init(args) do
    Process.flag(:trap_exit, true)

    {:ok, args}
  end

  @impl GenServer
  def handle_call(msg, from, state)
  def handle_call(:src, _, {src, _} = state), do: {:reply, src, state}
  def handle_call(:site, _, {_, site} = state), do: {:reply, site, state}

  @impl GenServer
  def terminate(_reason, {_, site}), do: File.rm_rf!(site)
end
