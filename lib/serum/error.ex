defmodule Serum.Error do
  @moduledoc """
  This module defines types for positive results or errors returned by
  functions in this project.
  """

  @type result :: positive | error

  @type positive :: :ok | {:ok, term}
  @type error    :: {:error, reason, err_details}

  @type reason      :: atom
  @type err_details :: no_detail | msg_detail | full_detail | nest_detail

  @type no_detail   :: nil
  @type msg_detail  :: message
  @type full_detail :: {message, file, line}
  @type nest_detail :: {term, [error]}

  @type message :: atom | String.t
  @type file    :: String.t
  @type line    :: non_neg_integer

  @spec filter_results([result], term) :: result
  def filter_results(results, from) do
    case Enum.filter(results, &(&1 != :ok)) do
      [] -> :ok
      errors when is_list(errors) ->
        {:error, :child_tasks, {from, errors}}
    end
  end

  @spec show(result, non_neg_integer) :: :ok
  def show(result, indent \\ 0)

  def show(:ok, indent) do
    IO.write String.duplicate("  ", indent)
    IO.puts "No errors detected."
  end

  def show({:ok, _}, indent) do
    show(:ok, indent)
  end

  def show({:error, reason, nil}, indent) do
    IO.write String.duplicate("  ", indent)
    perr "#{reason}"
  end

  def show({:error, _r, message}, indent) when is_binary(message) do
    IO.write String.duplicate("  ", indent)
    perr "#{message}"
  end

  def show({:error, _r, {message, file, 0}}, indent) do
    IO.write String.duplicate("  ", indent)
    perr "\x1b[97m#{file}:\x1b[0m #{message}"
  end

  def show({:error, _r, {message, file, line}}, indent) do
    IO.write String.duplicate("  ", indent)
    perr "\x1b[97m#{file}:#{line}:\x1b[0m #{message}"
  end

  def show({:error, :child_tasks, {from, errors}}, indent) do
    IO.write String.duplicate("  ", indent)
    IO.puts "\x1b[1;31mSeveral errors occurred from #{from}:\x1b[0m"
    Enum.each(errors, &show(&1, indent + 1))
  end

  defp perr(str) do
    IO.puts "\x1b[31m❌\x1b[0m  #{str}"
  end
end

defmodule Serum.PostError do
  defexception [reason: nil, path: nil]

  def message(e) do
    case e.reason do
      :filename -> "invalid post filename"
      :header   -> "invalid post header"
      _         -> "unspecified post error"
    end
  end
end

defmodule Serum.PageError do
  defexception [reason: nil, path: nil]

  def message(e) do
    case e.reason do
      :header -> "invalid page header"
      _       -> "unspecified page error"
    end
  end
end

defmodule Serum.JsonError do
  defexception [message: nil, file: nil]

  def message(e), do: e.message
end

defmodule Serum.TemplateError do
  defexception [message: nil, file: nil, line: nil]

  def message(e), do: e.message
end

defmodule Serum.ValidationError do
  defexception [schema: nil, errors: []]

  def message(e) do
    msg = "failed to validate JSON with `#{e.schema}` schema\n"
    errmsgs = for {msg, prop} <- e.errors, do: "\"#{prop}\": #{msg}"
    msg <> Enum.join(errmsgs, "\n")
  end
end

