defmodule Mix.Tasks.Serum.CLIHelper do
  @moduledoc false

  @version Mix.Project.config()[:version]

  @spec version_string() :: binary()
  def version_string do
    [
      :bright,
      "Serum -- Yet another simple static website generator\n",
      "Version #{@version}. Copyright (C) 2019 Dalgona. ",
      "<project-serum@dalgona.dev>\n",
      :reset
    ]
    |> IO.ANSI.format()
    |> IO.iodata_to_binary()
  end
end
