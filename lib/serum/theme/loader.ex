defmodule Serum.Theme.Loader do
  @moduledoc false

  _moduledocp = "Defines functions for loading a Serum theme."

  require Serum.V2.Result, as: Result
  alias Serum.Theme
  alias Serum.V2.Error

  @spec load_theme(term()) :: Result.t(Theme.t() | nil)
  def load_theme(maybe_spec)

  def load_theme(nil) do
    Agent.update(Theme, fn _ -> {nil, nil} end)
    Result.return(nil)
  end

  def load_theme(maybe_spec) do
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
    fun_repr = "#{module_name(module)}.init"

    case module.init(args) do
      {:ok, state} ->
        Result.return(state)

      {:error, %Error{} = error} ->
        Result.fail(Simple: ["#{fun_repr} returned an error:"], caused_by: [error])

      term ->
        Result.fail(Simple: ["#{fun_repr} returned an unexpected value: #{inspect(term)}"])
    end
  rescue
    exception -> Result.fail(Exception: [exception, __STACKTRACE__])
  end

  @spec update_agent(Theme.t(), term()) :: Result.t({})
  defp update_agent(theme, init_state) do
    Agent.update(Theme, fn _ -> {theme, init_state} end)
    Result.return()
  end

  @spec module_name(module()) :: binary()
  defp module_name(module) do
    module |> to_string() |> String.replace_prefix("Elixir.", "")
  end
end
