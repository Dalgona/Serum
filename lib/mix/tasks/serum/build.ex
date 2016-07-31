defmodule Mix.Tasks.Serum.Build do
  use Mix.Task

  @shortdoc "Rebuild the whole site"
  def run(_) do
    Serum.info
    Serum.build
  end
end
