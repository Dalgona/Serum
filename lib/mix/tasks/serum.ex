defmodule Mix.Tasks.Serum do
  @moduledoc """
  Prints a list of available Serum tasks.

      mix serum

  This task does not take any command line argument.
  """

  @shortdoc "Prints a list of available Serum tasks"

  use Mix.Task
  alias Serum.CLIUtils

  tasks = %{
    "serum" => "Prints this help message",
    "serum.build" => "Builds the Serum project",
    "serum.gen.page" => "Adds a new page to the current project",
    "serum.gen.post" => "Adds a new blog post to the current project",
    "serum.server" => "Starts the Serum development server"
  }

  max_length = tasks |> Map.keys() |> Enum.map(&String.length/1) |> Enum.max()

  tasks_msg =
    Enum.map(tasks, fn {name, description} ->
      [
        :cyan,
        String.pad_trailing(name, max_length),
        :reset,
        " # ",
        description,
        ?\n
      ]
    end)

  @impl true
  def run(args) do
    CLIUtils.parse_options(args, strict: [])

    [
      CLIUtils.version_string(),
      "\nAvailable tasks are:\n",
      unquote(tasks_msg),
      "\nPlease visit ",
      :bright,
      "https://dalgona.dev/Serum",
      :reset,
      " for full documentations."
    ]
    |> IO.ANSI.format()
    |> Mix.shell().info()
  end
end
