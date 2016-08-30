defmodule Serum.Cmdline do
  @moduledoc """
  This module contains the entry point for the command line program
  (`Serum.Cmdline.main/1`).
  """

  def main([]) do
    info
    usage
  end

  def main(["init"|args]) do
    info
    case args do
      [] -> Serum.Init.init "."
      [dir|_] -> Serum.Init.init dir
    end
  end

  def main(["build"|args]) do
    info
    {opts, args, errors} =
      OptionParser.parse args, strict: [parallel: :boolean, output: :string], aliases: [p: :parallel, o: :output]
    mode = Keyword.get(opts, :parallel) && :parallel || :sequential
    out = Keyword.get(opts, :output)
    case {args, errors} do
      {[], []} -> Serum.Build.build ".", out, mode, true
      {[dir|_], []} -> Serum.Build.build dir, out, mode, true
      {_, _} -> usage
    end
  end

  def main(["server"|args]) do
    info
    {opts, args, errors} =
      OptionParser.parse args, strict: [port: :integer], aliases: [p: :port]
    port = Keyword.get(opts, :port) || 8080
    case {args, errors} do
      {[], []} -> Serum.DevServer.run ".", port
      {[dir|_], []} -> Serum.DevServer.run dir, port
      {_, _} -> usage
    end
  end

  def main(["help"|_]) do
    info
    usage
  end

  def main(["version"|_]), do: info

  def main(_args) do
    info
    usage
  end

  defp info() do
    IO.puts "[1mSerum -- Yet another simple static website generator"
    IO.puts "Version 0.9.0. Copyright (C) 2016 Dalgona. <dalgona@hontou.moe>[0m\n"
  end

  defp usage() do
    IO.puts """
    Usage: serum <task>

      Available Tasks:
      [96minit[0m [dir]               Initializes a new Serum project

      [96mbuild[0m [options] [dir]    Builds an existing Serum project
        -p, --parallel         Builds the pages parallelly
        -o, --output <outdir>  Specifies the output directory

      [96mhelp[0m                     Shows this help message

      [96mversion[0m                  Shows the version information
    """
  end
end
