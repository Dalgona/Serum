defmodule Serum.Util do
  @moduledoc """
  This module provides some frequently used shortcut functions. These functions
  are inlined by the compiler.
  """

  @doc "Writes `str` to a file specified by `fname`."
  @spec fwrite(String.t, String.t) :: :ok
  @compile {:inline, fwrite: 2}

  def fwrite(fname, str),
    do: File.open! fname, [:write, :utf8], &IO.write(&1, str)

  @doc "Prints a warning message to stderr."
  @spec warn(String.t) :: :ok
  @compile {:inline, warn: 1}

  def warn(str),
    do: IO.puts :stderr, "\x1b[33m * #{str}\x1b[0m"

  @spec owner :: pid

  def owner do
    {:links, links} = Process.info self(), :links
    [self()|links]
    |> Enum.reject(fn pid ->
      lookups =
        [:project_info, :build_data, :post_info]
        |> Enum.map(fn key -> Registry.lookup Serum.Registry, {key, pid} end)
        |> Enum.uniq
      lookups == [[]]
    end)
    |> hd()
  end
end
