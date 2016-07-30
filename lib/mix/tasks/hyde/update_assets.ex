defmodule Mix.Tasks.Hyde.UpdateAssets do
  use Mix.Task

  @shortdoc "Just copy the assets and media directory without building the whole project"
  def run(_) do
    Hyde.info
    Hyde.copy_assets
  end
end
