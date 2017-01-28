defmodule Serum.Build.BuildData do
  @spec start_link(String.t) :: {:ok, pid}

  def start_link(id) do
    name = {:via, Registry, {Serum.Registry, id}}
    Agent.start_link fn -> %{} end, name: name
  end

  @spec init(String.t) :: :ok

  def init(id) do
    name = {:via, Registry, {Serum.Registry, id}}
    Agent.update name, fn _ -> %{} end
  end

  @spec put(String.t, String.t, term) :: :ok

  def put(id, key, value) do
    name = {:via, Registry, {Serum.Registry, id}}
    Agent.update name, &Map.put(&1, key, value)
  end

  @spec put(String.t, String.t, String.t, term) :: :ok

  def put(id, path, key, value) do
    put id, path <> "__" <> key, value
  end

  @spec get(String.t, String.t) :: term | nil

  def get(id, key) do
    name = {:via, Registry, {Serum.Registry, id}}
    Agent.get name, &Map.get(&1, key)
  end

  @spec get(String.t, String.t, String.t) :: term | nil

  def get(id, path, key) do
    get id, path <> "__" <> key
  end

  @spec delete(String.t, String.t) :: :ok

  def delete(id, key) do
    name = {:via, Registry, {Serum.Registry, id}}
    Agent.update name, &Map.delete(&1, key)
  end

  @spec delete(String.t, String.t, String.t) :: :ok

  def delete(id, path, key) do
    delete id, path <> "__" <> key
  end
end
