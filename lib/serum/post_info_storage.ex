defmodule Serum.PostInfoStorage do
  defmacro name(owner) do
    quote do
      {:via, Registry, {Serum.Registry, {:post_info, unquote(owner)}}}
    end
  end

  def start_link(owner) do
    Agent.start_link fn -> [] end, name: name(owner)
  end

  def init(owner) do
    Agent.update name(owner), fn _ -> [] end
  end

  def add(owner, info) do
    Agent.update name(owner), &([info|&1])
  end

  def all(owner) do
    posts = Agent.get name(owner), &(&1)
    Enum.sort_by posts, &(&1.file)
  end

  def stop(owner) do
    Agent.stop name(owner)
  end
end
