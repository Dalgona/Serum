defmodule Serum.Theme.Cleanup do
  @moduledoc false

  _moduledocp = "Provides functions for cleaning up unloading a loaded theme."

  require Serum.ForeignCode, as: ForeignCode
  require Serum.V2.Result, as: Result
  import Serum.V2.Console
  alias Serum.Error.Format
  alias Serum.Theme
  alias Serum.V2.Error

  @doc false
  @spec cleanup() :: Result.t({})
  def cleanup do
    case Agent.get(Theme, & &1) do
      {nil, _} ->
        Result.return()

      {%Theme{module: module}, state} ->
        do_cleanup(module, state)
        Agent.update(Theme, fn _ -> {nil, nil} end)
        Result.return()
    end
  end

  @spec do_cleanup(module(), term()) :: Result.t({})
  defp do_cleanup(module, state) do
    case call_cleanup(module, state) do
      {:ok, _} ->
        Result.return()

      {:error, %Error{} = error} ->
        message = "an error occurred while cleaning up a theme"
        {:error, warn} = Result.fail(message, caused_by: [error])

        put_err(:warn, Format.format_text(warn, 0))
    end
  end

  @spec call_cleanup(module(), term()) :: Result.t({})
  defp call_cleanup(module, state) do
    ForeignCode.call module.cleanup(state) do
      _ -> Result.return()
    end
  end
end
