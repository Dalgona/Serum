defmodule Serum.Template.Storage do
  @moduledoc false

  _moduledocp = "An agent which stores compiled templates and includes."

  use Agent
  alias Serum.Template

  @initial_value %{template: %{}, include: %{}}

  defguardp is_valid_type(type) when type in ~w(template include)a

  @spec start_link(term()) :: Agent.on_start()
  def start_link(_) do
    Agent.start_link(fn -> @initial_value end, name: __MODULE__)
  end

  @spec load(Template.collection(), Template.type()) :: :ok
  def load(templates, type) when is_valid_type(type) do
    Agent.update(__MODULE__, &Map.put(&1, type, templates))
  end

  @spec get(binary(), Template.type()) :: Template.t() | nil
  def get(name, type) when is_valid_type(type) do
    Agent.get(__MODULE__, &get_in(&1, [type, name]))
  end

  @spec put(binary(), Template.type(), Template.t()) :: :ok
  def put(name, type, template) when is_valid_type(type) do
    Agent.update(__MODULE__, &put_in(&1, [type, name], template))
  end

  @spec reset() :: :ok
  def reset, do: Agent.update(__MODULE__, fn _ -> @initial_value end)
end
