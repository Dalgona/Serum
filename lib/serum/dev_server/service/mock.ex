defmodule Serum.DevServer.Service.Mock do
  @moduledoc """
  A fake implementation of `Serum.DevServer.Service` behaviour for testing.
  """

  use Agent
  alias Serum.DevServer.Service

  @behaviour Service

  @doc false
  @spec start_link(binary(), binary()) :: {:ok, pid()} | {:error, term()}
  def start_link(src, site) do
    Agent.start_link(fn -> {src, site} end, name: __MODULE__)
  end

  @impl Service
  @spec rebuild() :: :ok
  def rebuild, do: :ok

  @impl Service
  @spec source_dir() :: binary()
  def source_dir, do: Agent.get(__MODULE__, fn {src, _} -> src end)

  @impl Service
  @spec site_dir() :: binary()
  def site_dir, do: Agent.get(__MODULE__, fn {_, site} -> site end)

  @impl Service
  @spec port() :: pos_integer()
  def port, do: 8080

  @impl Service
  @spec dirty?() :: boolean()
  def dirty?, do: false

  @impl Service
  @spec subscribe() :: :ok
  def subscribe, do: :ok
end
