defmodule Serum.CLI.Task do
  @moduledoc false

  @callback run(task_name :: binary, args :: [binary]) :: any
end

defmodule Serum.CLI do
  @moduledoc """
  This module contains the entry point for the command line program
  (`Serum.CLI.main/1`).
  """

  @behaviour Serum.CLI.Task

  @task_map %{
    "build" => Serum.CLI.Build,
    "help" => __MODULE__,
    "init" => Serum.CLI.Init,
    "server" => Serum.CLI.Server,
    "version" => __MODULE__
  }

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
    case @task_map[task] do
      nil -> usage()
      task_module -> task_module.run(task, opts)
    end
  end

  def run("version", _), do: :ok
  def run("help", _), do: usage()

  @spec info() :: :ok

  defp info() do
    {:ok, vsn} = :application.get_key :serum, :vsn
    IO.puts """
    \x1b[1mSerum -- Yet another simple static website generator
    Version #{vsn}. Copyright (C) 2016 Dalgona. <dalgona@hontou.moe>\x1b[0m
    """
  end

  @spec usage() :: :ok

  def usage() do
    IO.puts """
    Usage: serum <task>

      Available Tasks:
      \x1b[96minit\x1b[0m [options] [dir]     Initializes a new Serum project
        dir                    (optional) Directory of new Serum project
        -f, --force            Forces initialization even if dir is not empty

      \x1b[96mbuild\x1b[0m [options] [dir]    Builds an existing Serum project
        dir                    (optional) Path to a Serum project
        -p, --parallel         Builds the pages parallelly
        -o, --output <outdir>  Specifies the output directory

      \x1b[96mserver\x1b[0m [options] [dir]   Starts a web server
        dir                    (optional) Path to a Serum project
        -p, --port             Specifies HTTP port the server listens on
                               (Default is 8080)

      \x1b[96mhelp\x1b[0m                     Shows this help message

      \x1b[96mversion\x1b[0m                  Shows the version information
    """
  end
end
