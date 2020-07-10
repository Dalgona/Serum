defmodule Serum.V2.BuildContext do
  @moduledoc """
  A struct containing various information used during a build process.

  ## Fields

  - `project` - a loaded project.
  - `source_dir` - a directory which the loaded project is loacted at.
  - `dest_dir` - a directory which a website will be built into.
  """

  alias Serum.V2.Project

  @type t :: %__MODULE__{
          project: Project.t(),
          source_dir: binary(),
          dest_dir: binary()
        }

  defstruct project: %Project{},
            source_dir: "",
            dest_dir: ""
end
