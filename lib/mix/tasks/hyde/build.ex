defmodule Mix.Tasks.Hyde.Build do
  use Mix.Task

  @shortdoc "Rebuild the whole site"
  def run(_) do
    Hyde.info
    Hyde.build
  end
end
