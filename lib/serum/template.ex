defmodule Serum.Template do
  @moduledoc """
  Defines a struct which stores a template and its information.

  This module also provides an interface to an Agent, which is responsible for
  holding templates and includable templates.
  """

  @type t() :: %__MODULE__{
          type: template_type(),
          file: binary(),
          ast: Macro.t()
        }
  @type template_type() :: :template | :include

  defstruct type: :template, file: nil, ast: nil

  @spec new(Macro.t(), template_type(), binary()) :: t()
  def new(ast, type, path) do
    %__MODULE__{
      type: type,
      file: path,
      ast: ast
    }
  end

  #
  # Agent Wrappers
  #

  use Agent

  def start_link(_args) do
    initial = %{templates: %{}, includes: %{}}
    Agent.start_link(fn -> initial end, name: __MODULE__)
  end

  @spec load(map(), template_type()) :: :ok
  def load(map, type)

  def load(%{} = map, :template) do
    Agent.update(__MODULE__, &%{&1 | templates: map})
  end

  def load(%{} = map, :include) do
    Agent.update(__MODULE__, &%{&1 | includes: map})
  end

  @spec get(binary(), template_type()) :: t() | nil
  def get(template_name, type \\ :template)

  def get(template_name, :template) do
    Agent.get(__MODULE__, & &1.templates[template_name])
  end

  def get(template_name, :include) do
    Agent.get(__MODULE__, & &1.includes[template_name])
  end
end
