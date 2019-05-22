defmodule Serum do
  @moduledoc """
  Defines Serum OTP application.

  Serum is a simple static website generator written in Elixir programming
  language. The goal of this project is to provide the way to create awesome
  static websites with little effort.

  This documentation is for developers and advanced users. For the getting
  started guide and the user manual, please visit [the official Serum
  website](https://dalgona.github.io/Serum).

  Also, documentations for modules related to the internal operation of Serum
  are hidden. But such modules are still documented in [their source
  codes](https://github.com/Dalgona/Serum).
  """

  use Application
  alias Serum.GlobalBindings
  alias Serum.IOProxy
  alias Serum.Plugin

  @doc """
  Starts the `:serum` application.

  This starts a supervisor process which manages some children maintaining
  states or data required for execution of Serum.
  """
  def start(_type, _args) do
    children = [
      GlobalBindings,
      IOProxy,
      Plugin
    ]

    opts = [strategy: :one_for_one, name: Serum.Supervisor]
    {:ok, _pid} = Supervisor.start_link(children, opts)
  end
end
