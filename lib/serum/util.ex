defmodule Serum.Util do
  @moduledoc """
  This module provides some frequently used shortcut functions. These functions
  are inlined by the compiler.
  """

  @doc "Prints a warning message to stderr."
  @spec warn(binary) :: :ok

  defmacro warn(str) do
    quote do
      IO.puts(:stderr, "\x1b[33m * #{unquote(str)}\x1b[0m")
    end
  end

  @doc "Displays which file is generated."
  @spec msg_gen(binary, binary) :: :ok

  defmacro msg_gen(dest) do
    quote do
      IO.puts("\x1b[92m  GEN  \x1b[0m#{unquote(dest)}")
    end
  end

  defmacro msg_gen(src, dest) do
    quote do
      IO.puts("\x1b[92m  GEN  \x1b[0m#{unquote(src)} -> #{unquote(dest)}")
    end
  end

  @doc "Displays which directory is created."
  @spec msg_mkdir(binary) :: :ok

  defmacro msg_mkdir(dir) do
    quote do
      IO.puts("\x1b[96m MKDIR \x1b[0m#{unquote(dir)}")
    end
  end
end
