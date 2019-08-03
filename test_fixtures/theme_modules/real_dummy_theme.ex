defmodule Serum.RealDummyTheme do
  @behaviour Serum.Theme

  def name, do: "Real Dummy Theme"
  def author, do: "John Doe"
  def description, do: "This is a real dummy theme."
  def legal, do: "Use this for testing purposes only."
  def version, do: "0.1.0"
  def serum, do: ">= 0.1.0"

  def get_templates, do: Path.wildcard(Path.join(dir(), "templates/*"))
  def get_includes, do: Path.wildcard(Path.join(dir(), "includes/*"))
  def get_assets, do: Path.join(dir(), "assets")

  defp dir do
    Agent.get(Serum.TestAgent, & &1)
  end
end
