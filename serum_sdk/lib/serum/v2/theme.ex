defmodule Serum.V2.Theme do
  @moduledoc """
  A behaviour that all Serum theme module must implement.

  A Serum theme is a set of predefined templates and assets which are used
  while Serum is building a project.

  More specifically, a Serum theme is a Mix project which has the following
  contents:

  - Module(s) that implement this behaviour,
  - And theme files such as templates, includes, and other assets.
    These files are usually stored in the `priv/` directory, or may be
    dynamically created while a theme is being loaded.

  Any Serum theme package must have at least on module that implements this
  behaviour, as Serum will call callbacks of this behaviour to ensure that your
  modules provide appropriate theme resources when needed.

  You may `use` this module in your theme module. Inserting
  `use Serum.V2.Theme` directive will...

  - Add `@behaviour Serum.V2.Theme` module attribute,
  - Require the `Serum.V2.Result` module and make an alias as `Result`,
  - And add a default implementation of the `version/0` callback, which returns
    the version specified in `mix.exs`.
  """

  alias Serum.V2.Result

  @type spec :: module() | {module(), options()}
  @type options :: [args: term()]

  @spec __using__(Macro.t()) :: Macro.t()
  defmacro __using__(_opts) do
    quote do
      require Serum.V2.Result, as: Result

      @behaviour unquote(__MODULE__)

      @impl true
      def version, do: Mix.Project.config()[:version]

      defoverridable version: 0
    end
  end

  @doc "Returns the name of the theme."
  @callback name() :: binary()

  @doc "Returns a short, one-liner description about the theme."
  @callback description() :: binary()

  @doc """
  Returns the theme version.

  The returned value must follow the semantic versioning scheme. Refer to
  [this document](https://hexdocs.pm/elixir/Version.html#module-requirements)
  for the string format.
  """
  @callback version() :: binary()

  @doc """
  Called after the theme module is loaded.

  Start any necessary processes or create temporary files or directories which
  will be used while Serum builds a website project.

  The returned value will be used as the state for the loaded theme, which
  can be accessible from `c:cleanup/1`, `c:get_includes/1`, `c:get_templates/1`,
  and `c:get_assets/1` callbacks.
  """
  @callback init(args :: term()) :: Result.t(term())

  @doc """
  Called when Serum has finished building a website project.

  Release or delete any resources created by the `c:init/1` callback here.
  """
  @callback cleanup(state :: term()) :: Result.t({})

  @doc """
  Returns a list of paths to include files.

  All paths in the list must end with `".html.eex"`. Any path that does not
  follow this rule will be ignored.

  ## Example Return Expression

      Serum.V2.Result.return([
        "/path/to/theme/priv/includes/nav.html.eex",
        "/path/to/theme/priv/includes/sidebar.html.eex",
        "/path/to/theme/priv/includes/footer.html.eex"
      ])
  """
  @callback get_includes(state :: term()) :: Result.t([binary()])

  @doc """
  Returns a list of paths to template files.

  All paths in the list must end with `".html.eex"`. Any path that does not
  follow this rule will be ignored.

  ## Example Return Expression

      Serum.V2.Result.return([
        "/path/to/theme/priv/templates/base.html.eex",
        "/path/to/theme/priv/templates/list.html.eex",
        "/path/to/theme/priv/templates/post.html.eex"
      ])
  """
  @callback get_templates(state :: term()) :: Result.t([binary()])

  @doc """
  Returns a path to the assets directory.

  All files in the directory specified by the returned value will be copied to
  the destination assets directory using `File.cp_r/2` function.

  ## Example Return Expression 1

      Serum.V2.Result.return("/path/to/theme/priv/assets")

  ## Example Return Expression 2

  This callback may return `false` to indicate that no asset will be copied.

      Serum.V2.Result.return(false)
  """
  @callback get_assets(state :: term()) :: Result.t(binary() | false)
end
