defmodule Mix.Tasks.Serum.CLIHelper do
  @moduledoc false

  @version Mix.Project.config()[:version]

  @spec version_string() :: binary()
  def version_string do
    """
    \x1b[1mSerum -- Yet another simple static website generator
    Version #{@version}. Copyright (C) 2019 Dalgona. <dalgona@hontou.moe>
    \x1b[0m
    """
  end
end
