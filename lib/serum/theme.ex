defmodule Serum.Theme do
  @moduledoc """
  A behaviour that all Serum theme module must implement.

  A Serum theme is a set of predefined templates and assets which are used
  while Serum is building a project.

  More specifically, a Serum theme is a Mix project which has the following
  contents:

  - Modules that implement this behaviour,
  - And theme files such as templates, includes, and other assets.
    These files are usually stored in the `priv/` directory.

  Your theme package must have at least one module that implements this
  behaviour, as Serum will call callbacks of this behaviour to ensure that your
  modules provide appropriate theme resources when needed.

  ## Using Serum Themes

  To use a Serum theme, you first need to add the theme package to your
  dependencies list.

      # mix.exs
      defp deps do
      [
        {:serum, "~> 1.0"},
        # ...

        # If the theme is available on Hex.pm:
        {:serum_theme_sample, "~> 1.0"}

        # If the theme is available on somewhere else:
        {:serum_theme_sample, git: "https://github.com/..."}
      ]
      end

  Fetch and build the theme package using `mix`.

      $ mix do deps.get, deps.compile

  To configure your Serum project to use a theme, you need to put a `:theme`
  key in your `serum.exs`.

      # serum.exs:
      %{
        theme: Serum.Themes.Sample,
        # ...
      }

  Read the documentation provided by the theme author, to see the list of files
  the theme consists of. Files provided by the theme are always overridden by
  corresponding files in your project directory. So it is safe to remove files
  from your project if the theme has ones.

  Finally, try building your project to see if the theme is applied correctly.

      $ mix serum.server
      # Or,
      $ MIX_ENV=prod mix serum.build
  """

  use Agent
  require Serum.V2.Result, as: Result
  import Serum.V2.Console
  alias Serum.ForeignCode
  alias Serum.Theme.Cleanup
  alias Serum.Theme.Loader

  defstruct module: nil,
            name: "",
            description: "",
            version: Version.parse!("0.0.0"),
            args: nil

  @type t :: %__MODULE__{
          module: module() | nil,
          name: binary(),
          description: binary(),
          version: Version.t(),
          args: term()
        }

  @type spec :: {module(), options()}
  @type options :: [args: term()]

  @doc false
  @spec start_link(any()) :: Agent.on_start()
  def start_link(_) do
    Agent.start_link(fn -> {nil, nil} end, name: __MODULE__)
  end

  @doc false
  @spec load(term()) :: Result.t(t() | nil)
  defdelegate load(maybe_spec), to: Loader

  @doc false
  @spec cleanup() :: Result.t({})
  defdelegate cleanup, to: Cleanup

  @doc false
  @spec show_info(t() | nil) :: Result.t({})
  def show_info(theme_or_nil)
  def show_info(nil), do: Result.return()

  def show_info(theme) do
    msg = [
      [:bright, theme.name, " v", to_string(theme.version), :reset],
      " (#{ForeignCode.module_name(theme.module)})\n",
      [:light_black, theme.description]
    ]

    put_msg(:theme, msg)
  end
end
