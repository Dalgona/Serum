defmodule Serum.Template.Storage do
  @moduledoc false

  _moduledocp = "An agent which stores compiled templates and includes."

  use Agent
  require Serum.V2.Result, as: Result
  alias Serum.Template

  @initial_value %{template: %{}, include: %{}}

  defguardp is_valid_type(type) when type in ~w(template include)a

  @spec start_link(term()) :: Agent.on_start()
  def start_link(_) do
    Agent.start_link(fn -> @initial_value end, name: __MODULE__)
  end

  @spec load(Template.collection(), Template.type()) :: Result.t({})
  def load(templates, type) when is_valid_type(type) do
    Agent.update(__MODULE__, &Map.put(&1, type, templates))
    Result.return()
  end

  @spec get(binary(), Template.type()) :: Result.t(Template.t())
  def get(name, type) when is_valid_type(type) do
    case Agent.get(__MODULE__, &get_in(&1, [type, name])) do
      %Template{} = template -> Result.return(template)
      nil -> Result.fail(Simple: ["#{type} not found: \"#{name}\""])
    end
  end

  @spec put(binary(), Template.type(), Template.t()) :: Result.t({})
  def put(name, type, template) when is_valid_type(type) do
    Agent.update(__MODULE__, &put_in(&1, [type, name], template))
    Result.return()
  end

  @spec reset() :: Result.t({})
  def reset do
    Agent.update(__MODULE__, fn _ -> @initial_value end)
    Result.return()
  end
end
