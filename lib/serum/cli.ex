defmodule Serum.CLI.Task do
  @moduledoc false

  @callback tasks() :: [binary]
  @callback run(task_name :: binary, args :: [binary]) :: {:cli_exit, integer}
  @callback short_help(task_name :: binary) :: binary
  @callback synopsis(task_name :: binary) :: binary
  @callback help(task_name :: binary) :: binary | false
end

defmodule Serum.CLI do
  @moduledoc """
  This module contains the entry point for the command line program
  (`Serum.CLI.main/1`).
  """

  import Serum.Util

  @behaviour Serum.CLI.Task

  @main_task_providers [
    Serum.CLI.Init,
    Serum.CLI.Build,
    Serum.CLI.Server,
    __MODULE__
  ]

  @doc "The entry point for Serum command-line program."
  @spec main(args :: [binary]) :: any

  def main(args)

  def main([]) do
    info()
    usage()
  end

  def main(args) do
    info()
    [task|opts] = args
    with task_module when not is_nil(task_module) <- task_map()[task],
         {:cli_exit, status} <- task_module.run(task, opts)
    do
      System.halt status
    else
      nil ->
        usage()
        System.halt 2
      x ->
        warn "The task returned unexpected value: #{x}"
        System.halt 1
    end
  end

  @spec task_map() :: %{required(binary) => {atom, binary}}

  defp task_map do
    providers = @main_task_providers
    Enum.reduce providers, %{}, fn module, acc ->
      temp =
        for task when is_binary(task) <- module.tasks(), into: %{} do
          {task, module}
        end
      Map.merge acc, temp
    end
  end

  @spec info() :: :ok

  defp info() do
    {:ok, v} = :application.get_key :serum, :vsn
    IO.puts "\x1b[1mSerum -- Yet another simple static website generator\n"
      <> "Version #{v}. Copyright (C) 2016 Dalgona. <dalgona@hontou.moe>\x1b[0m"
  end

  @spec usage() :: :ok

  def usage() do
    IO.puts """

    Usage: serum <TASK>

    Available Tasks:
      (run "serum help TASK" to read detailed description for each TASK)
    """
    display_tasks @main_task_providers
    IO.puts """

    Visit http://dalgona.hontou.moe/Serum for the getting started guide,
    the official Serum documentation and more.
    """
  end

  @spec display_tasks([atom]) :: :ok

  defp display_tasks(task_providers) do
    {names, descriptions} =
      task_providers
      |> get_short_help
      |> Enum.unzip
    max_name_len = names |> Enum.map(&String.length/1) |> Enum.max
    padded_names = Enum.map names, &String.pad_trailing(&1, max_name_len)
    [padded_names, descriptions]
    |> Enum.zip
    |> Enum.each(fn {name, desc} ->
      IO.puts "  \x1b[96m#{name}\x1b[0m -- #{desc}"
    end)
  end

  @spec get_short_help([atom]) :: [{binary, binary}]

  defp get_short_help(task_providers) do
    task_providers
    |> Enum.map(&{&1, &1.tasks()})
    |> Enum.map(fn {mod, l} -> Enum.map l, &{&1, mod.short_help(&1)} end)
    |> List.flatten
  end

  #
  # Serum.CLI.Task BEHAVIOUR IMPLEMENTATION
  #

  def tasks, do: ["help", "version"]

  def run("help", []) do
    usage()
    {:cli_exit, 0}
  end

  def run("help", [arg|_]) do
    case task_map()[arg] do
      nil ->
        usage()
        {:cli_exit, 2}
      mod ->
        IO.ANSI.Docs.print_heading mod.synopsis arg
        case mod.help arg do
          text when is_binary(text) ->
            IO.ANSI.Docs.print text
          false ->
            IO.puts "This task does not provide help text.\n"
        end
        {:cli_exit, 0}
    end
  end

  def run("version", _), do: {:cli_exit, 0}

  def short_help("help"), do: "Show help messages"
  def short_help("version"), do: "Show version information"

  def synopsis("help"), do: "serum help [TASK]"
  def synopsis("version"), do: "serum version"

  def help("help"), do: false
  def help("version"), do: false
end
