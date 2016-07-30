defmodule Mix.Tasks.Hyde.Info do
  use Mix.Task

  @showdoc "Displays information about this program"
  def run(_), do: Hyde.info
end
