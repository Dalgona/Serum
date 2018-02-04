defmodule Serum.GlobalBindings do
  @moduledoc """
  Provides an interface to an Agent which stores site-wide
  template variable bindings.
  """

  use Agent

  def start_link(_args) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @spec load(map()) :: :ok
  def load(%{} = map) do
    Agent.update(__MODULE__, fn _ -> map end)
  end

  @spec as_keyword() :: keyword()
  def as_keyword do
    Agent.get(__MODULE__, &Keyword.new/1)
  end

  @spec get(atom()) :: term()
  def get(key) do
    Agent.get(__MODULE__, & &1[key])
  end
end
