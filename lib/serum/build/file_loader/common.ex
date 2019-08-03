defmodule Serum.Build.FileLoader.Common do
  @moduledoc false

  _moduledocp = "Provides common functions shared by other file loader modules"

  alias Serum.Result

  @doc false
  @spec get_subdir(binary(), binary()) :: binary()
  def get_subdir(src, subdir) do
    (src == "." && subdir) || Path.join(src, subdir)
  end

  @doc false
  @spec read_files([binary()]) :: Result.t([Serum.File.t()])
  def read_files(paths) do
    paths
    |> Stream.map(&%Serum.File{src: &1})
    |> Enum.map(&Serum.File.read/1)
    |> Result.aggregate_values(:file_loader)
  end
end
