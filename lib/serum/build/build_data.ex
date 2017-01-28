defmodule Serum.Build.BuildData do
  defmacro name(owner) do
    quote do
      {:via, Registry, {Serum.Registry, {:build_data, unquote(owner)}}}
    end
  end

  @spec start_link(pid) :: {:ok, pid}

  def start_link(owner) do
    Agent.start_link fn -> %{} end, name: name(owner)
  end

  @spec init(pid) :: :ok

  def init(owner) do
    Agent.update name(owner), fn _ -> %{} end
  end

  @spec put(pid, String.t, term) :: :ok

  def put(owner, key, value) do
    Agent.update name(owner), &Map.put(&1, key, value)
  end

  @spec put(pid, String.t, String.t, term) :: :ok

  def put(owner, path, key, value) do
    put owner, path <> "__" <> key, value
  end

  @spec get(pid, String.t) :: term | nil

  def get(owner, key) do
    Agent.get name(owner), &Map.get(&1, key)
  end

  @spec get(pid, String.t, String.t) :: term | nil

  def get(owner, path, key) do
    get owner, path <> "__" <> key
  end

  @spec delete(pid, String.t) :: :ok

  def delete(owner, key) do
    Agent.update name(owner), &Map.delete(&1, key)
  end

  @spec delete(pid, String.t, String.t) :: :ok

  def delete(owner, path, key) do
    delete owner, path <> "__" <> key
  end

  @spec stop(pid) :: :ok

  def stop(owner) do
    Agent.stop name(owner)
  end
end
