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
    {opts, args, _errors} =
      OptionParser.parse args, strict: [parallel: :boolean, to: :string], aliases: [p: :parallel, t: :to]
    mode = Keyword.get(opts, :parallel) && :parallel || :sequential
    case args do
      [] -> Serum.Build.build ".", mode
      [dir|_] -> Serum.Build.build dir, mode
    end
  end

  def main(["version"|_]), do: info

  def main(_args) do
    info
    usage
  end

  defp info() do
    IO.puts "Serum -- Yet another simple static website generator"
    IO.puts "Version 0.9.0. Copyright (C) 2016 Dalgona. <dalgona@hontou.moe>\n"
  end

  defp usage() do
    IO.puts """
    Usage: serum <task>

      Available Tasks:
      init [dir]             Initializes a new Serum project

      build [options] [dir]  Builds an existing Serum project
        -p, --parallel       Parallel build
                             (Sequential build if this option is not specified)

      version                Shows the version information
    """
  end
end
