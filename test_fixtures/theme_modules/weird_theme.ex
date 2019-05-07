defmodule Serum.WeirdTheme do
  @behaviour Serum.Theme

  def name, do: "Dummy Theme"
  def description, do: "This is a dummy theme for testing."
  def author, do: "John Doe"
  def legal, do: "Copyleft"
  def version, do: "0.1.0"
  def serum, do: ">= 1.0.0"

  def get_includes do
    [
      "/foo/bar/includes/nav.html.eex",
      "/foo/bar/includes/sidebar.html.eex",
      "/foo/bar/includes/test.png",
      "/foo/bar/includes/test.md"
    ]
  end

  def get_templates do
    [
      "/foo/bar/templates/base.html.eex",
      "/foo/bar/templates/list.html.eex",
      "/foo/bar/templates/post.html.eex",
      "/foo/bar/templates/magic.html.eex",
      "/foo/bar/templates/test.png"
    ]
  end

  def get_assets, do: Agent.get(Serum.TestAgent, & &1)
end
