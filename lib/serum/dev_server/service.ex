defmodule Serum.DevServer.Service do
  @moduledoc false

  _moduledocp = """
  Provides some useful functions while the Serum development server is running.
  """

  alias Serum.V2.Result

  @doc "Rebuilds the current Serum project."
  @callback rebuild() :: :ok

  @doc "Returns the source directory."
  @callback source_dir() :: binary

  @doc "Returns the output directory (under temporary directory)."
  @callback site_dir() :: binary

  @doc "Returns the port number the server currently listening on."
  @callback port() :: pos_integer

  @doc "Checks if the source directory is marked as dirty."
  @callback dirty?() :: boolean

  @doc "Returne the result of the last website build."
  @callback last_build_result() :: Result.t(binary())

  @doc "Subscribes to this GenServer for notifications."
  @callback subscribe() :: :ok
end
