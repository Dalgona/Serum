defmodule Serum.IncompatibleTheme do
  @behaviour Serum.Theme

  def name, do: "Dummy Theme"
  def description, do: "This is a dummy theme for testing."
  def author, do: "John Doe"
  def legal, do: "Copyleft"
  def version, do: "0.1.0"
  def serum, do: "<= 0.0.0"

  def get_includes do
    [
      "/foo/bar/includes/nav.html.eex",
      "/foo/bar/includes/sidebar.html.eex"
    ]
  end

  def get_templates do
    [
      "/foo/bar/templates/base.html.eex",
      "/foo/bar/templates/list.html.eex",
      "/foo/bar/templates/post.html.eex"
    ]
  end

  def get_assets, do: "/foo/bar/assets/"
end
