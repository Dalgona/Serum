defmodule Mix.Tasks.Serum.Info do
  use Mix.Task

  @showdoc "Displays information about this program"
  def run(_), do: Serum.info
end
