defmodule Serum.GlobalBindings do
  @moduledoc false

  _moduledocp = """
  Provides an interface to an Agent which stores site-wide
  template variable bindings.
  """

  use Agent

  def start_link(_args) do
    Agent.start_link(fn -> {%{args: []}, [args: []]} end, name: __MODULE__)
  end

  @spec load(map()) :: :ok
  def load(%{} = map) do
    Agent.update(__MODULE__, fn {_, _} -> {map, Keyword.new(map)} end)
  end

  @spec put(atom(), term()) :: :ok
  def put(key, value) when is_atom(key) do
    Agent.update(__MODULE__, fn {map, _} ->
      new_map = Map.put(map, key, value)

      {new_map, Keyword.new(new_map)}
    end)
  end

  @spec as_keyword() :: keyword()
  def as_keyword do
    Agent.get(__MODULE__, fn {_, kw} -> kw end)
  end

  @spec get(atom()) :: term()
  def get(key) when is_atom(key) do
    Agent.get(__MODULE__, fn {map, _} -> map[key] end)
  end
end
