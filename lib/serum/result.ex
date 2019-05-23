defmodule Serum.Result do
  @moduledoc """
  This module defines types for positive results or errors returned by
  functions in this project.
  """

  import Serum.IOProxy, only: [put_err: 2]

  @type t :: :ok | error()
  @type t(type) :: {:ok, type} | error()

  @type error :: {:error, err_details()}

  @type err_details :: msg_detail() | full_detail() | nest_detail()

  @type msg_detail :: message()
  @type full_detail :: {message(), file(), line()}
  @type nest_detail :: {term(), [error()]}

  @type message :: binary()
  @type file :: binary()
  @type line :: non_neg_integer()

  @doc """
  Takes a list of result objects (without returned values) and checks if there
  is no error.

  Returns `:ok` if there is no error.

  Returns an aggregated error object if there is one or more errors.
  """
  @spec aggregate([t()], term()) :: t()
  def aggregate(results, from) do
    case Enum.reject(results, &succeeded?/1) do
      [] -> :ok
      errors when is_list(errors) -> {:error, {from, errors}}
    end
  end

  @doc """
  Takes a list of result objects (with returned values) and checks if there is
  no error.

  If there is no error, it returns `{:ok, list}` where `list` is a list of
  returned values.

  Returns an aggregated error object if there is one or more errors.
  """
  @spec aggregate_values([t(term)], term()) :: t([term()])
  def aggregate_values(results, from) do
    case Enum.reject(results, &succeeded?/1) do
      [] -> {:ok, Enum.map(results, &elem(&1, 1))}
      errors when is_list(errors) -> {:error, {from, errors}}
    end
  end

  @spec succeeded?(t() | t(term)) :: boolean()
  defp succeeded?(result)
  defp succeeded?(:ok), do: true
  defp succeeded?({:ok, _}), do: true
  defp succeeded?({:error, _}), do: false

  @doc "Prints an error object in a beautiful format."
  @spec show(t(), non_neg_integer()) :: :ok
  def show(result, indent \\ 0)

  def show(:ok, indent) do
    pad = String.duplicate("  ", indent)

    put_err(:info, pad <> "No error detected.")
  end

  def show({:ok, _result}, indent) do
    show(:ok, indent)
  end

  def show({:error, message}, indent) when is_binary(message) do
    pad = String.duplicate("  ", indent)

    put_err(:error, pad <> message)
  end

  def show({:error, {posix, file, 0}}, indent) when is_atom(posix) do
    message = posix |> :file.format_error() |> IO.iodata_to_binary()

    show({:error, {message, file, 0}}, indent)
  end

  def show({:error, {message, file, 0}}, indent) do
    pad = String.duplicate("  ", indent)

    put_err(:error, pad <> "#{file}: #{message}")
  end

  def show({:error, {message, file, line}}, indent) do
    pad = String.duplicate("  ", indent)

    put_err(:error, pad <> "#{file}:#{line}: #{message}")
  end

  def show({:error, {from, errors}}, indent) do
    pad = String.duplicate("  ", indent)

    put_err(:error, pad <> "\x1b[1;31m#{from} (#{length(errors)}):")
    Enum.each(errors, &show(&1, indent + 1))
  end
end
