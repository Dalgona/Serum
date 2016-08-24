defmodule Serum.Cmdline do
  @moduledoc """
  This module contains the entry point for the command line program
  (`Serum.Cmdline.main/1`).
  """

  def main(args) do
    info
    case args do
      ["init"] -> Serum.init "."
      ["init", dir] -> Serum.init dir
      ["build"] -> Serum.build "."
      ["build", dir] -> Serum.build dir
      ["version"|_] -> nil
      _ -> usage
    end
  end

  defp info() do
    IO.puts "Serum -- Yet another simple static website generator"
    IO.puts "Version 0.9.0. Copyright (C) 2016 Dalgona. <dalgona@hontou.moe>\n"
  end

  defp usage() do
    IO.puts "Error: Invalid argument."
    IO.puts "Usage: serum init [<dir>]"
    IO.puts "       serum build [<dir>]"
    IO.puts "       serum version"
  end
end
