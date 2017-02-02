defmodule Serum.TagStorage do
  defmacro name(owner) do
    quote do
      {:via, Registry, {Serum.Registry, {:tag_storage, unquote(owner)}}}
    end
  end

  def start_link(owner) do
    Agent.start_link fn -> %{} end, name: name(owner)
  end

  def init(owner) do
    Agent.update name(owner), fn _ -> %{} end
  end

  def all(owner) do
    Agent.get name(owner), &(&1)
  end

  def tags(owner) do
    all = Agent.get name(owner), &(&1)
    for {tag, mapset} <- all, into: %{}, do: {tag, MapSet.size(mapset)}
  end

  def add_to_tag(owner, tag, info) do
    Agent.update name(owner), fn tagmap ->
      Map.update tagmap, tag, MapSet.new([info]), &MapSet.put(&1, info)
    end
  end

  def stop(owner) do
    Agent.stop name(owner)
  end
end
