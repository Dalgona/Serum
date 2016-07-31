defmodule Mix.Tasks.Serum.UpdateAssets do
  use Mix.Task

  @shortdoc "Just copy the assets and media directory without building the whole project"
  def run(_) do
    Serum.info
    Serum.copy_assets
  end
end
