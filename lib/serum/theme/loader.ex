defmodule Serum.Theme.Loader do
  @moduledoc false

  _moduledocp = "Defines functions for loading a Serum theme."

  require Serum.ForeignCode, as: ForeignCode
  require Serum.V2.Result, as: Result
  alias Serum.Theme

  @spec load(term()) :: Result.t(Theme.t() | nil)
  def load(maybe_spec)

  def load(nil) do
    Agent.update(Theme, fn _ -> {nil, nil} end)
    Result.return(nil)
  end

  def load(maybe_spec) do
    Result.run do
      spec <- normalize_spec(maybe_spec)
      theme <- make_theme(spec)
      init_state <- init_theme(theme)
      update_agent(theme, init_state)

      Result.return(theme)
    end
  end

  @spec normalize_spec(term()) :: Result.t(Plugin.spec())
  defp normalize_spec(maybe_spec)
  defp normalize_spec(module) when is_atom(module), do: Result.return({module, []})

  defp normalize_spec({module, opts}) when is_atom(module) and is_list(opts) do
    if Keyword.keyword?(opts) do
      Result.return({module, opts})
    else
      message = "expected the second tuple element to be a keyword list, got: #{inspect(opts)}"

      Result.fail(Simple: [message])
    end
  end

  defp normalize_spec(x) do
    Result.fail(Simple: ["#{inspect(x)} is not a valid Serum theme specification"])
  end

  @spec make_theme(Theme.spec()) :: Result.t(Theme.t())
  defp make_theme({module, opts}) do
    Result.return(%Theme{
      module: module,
      name: module.name(),
      description: module.description(),
      version: Version.parse!(module.version()),
      args: opts[:args]
    })
  rescue
    exception -> Result.fail(Exception: [exception, __STACKTRACE__])
  end

  @spec init_theme(Theme.t()) :: Result.t(term())
  defp init_theme(%Theme{module: module, args: args}) do
    ForeignCode.call module.init(args) do
      state -> Result.return(state)
    end
  end

  @spec update_agent(Theme.t(), term()) :: Result.t({})
  defp update_agent(theme, init_state) do
    Agent.update(Theme, fn _ -> {theme, init_state} end)
    Result.return()
  end
end
