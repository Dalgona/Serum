defmodule Serum.Payload do
  @moduledoc """
  This module contains static data used to initialize a new Serum project.
  """

  @spec template(atom) :: binary
  @spec include(atom) :: binary

  resources_dir =
    :serum
    |> :code.priv_dir()
    |> Path.join("build_resources")

  globs = [
    template: "templates/*.html.eex",
    include: "includes/*.html.eex"
  ]

  for {def_name, glob} <- globs do
    files = resources_dir |> Path.join(glob) |> Path.wildcard()

    for file <- files do
      data = File.read!(file)
      basename = Path.basename(file, ".html.eex")

      def unquote(def_name)(unquote(basename)) do
        unquote(data)
      end
    end
  end
end
