defmodule Serum.Build.FileLoader.Common do
  @moduledoc false

  _moduledocp = "Provides common functions shared by other file loader modules"

  alias Serum.Result
  alias Serum.V2

  @doc false
  @spec get_subdir(binary(), binary()) :: binary()
  def get_subdir(src, subdir) do
    (src == "." && subdir) || Path.join(src, subdir)
  end

  @doc false
  @spec read_files([binary()]) :: Result.t([V2.File.t()])
  def read_files(paths) do
    paths
    |> Stream.map(&%V2.File{src: &1})
    |> Enum.map(&V2.File.read/1)
    |> Result.aggregate("failed to load files:")
  end
end
