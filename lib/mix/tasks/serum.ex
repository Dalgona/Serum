defmodule Mix.Tasks.Serum do
  @moduledoc """
  Prints a list of available Serum tasks.

      mix serum

  This task does not take any command line argument.
  """

  @shortdoc "Prints a list of available Serum tasks"

  use Mix.Task

  @version Mix.Project.config()[:version]
  @b IO.ANSI.bright()
  @c IO.ANSI.cyan()
  @r IO.ANSI.reset()

  @impl true
  def run(_) do
    """
    #{@b}Serum -- Yet another simple static website generator
    Version #{@version}. Copyright (C) 2019 Dalgona. <dalgona@hontou.moe>#{@r}

    Available tasks are:
    #{@c}mix serum          #{@r}# Prints this help message
    #{@c}mix serum.build    #{@r}# Builds the Serum project
    #{@c}mix serum.gen.page #{@r}# Adds a new page to the current project
    #{@c}mix serum.gen.post #{@r}# Adds a new blog post to the current project
    #{@c}mix serum.server   #{@r}# Starts the Serum development server

    Please visit #{@b}http://dalgona.github.io/Serum#{@r}
    for full documentations.
    """
    |> String.trim_trailing()
    |> Mix.shell().info()
  end
end
