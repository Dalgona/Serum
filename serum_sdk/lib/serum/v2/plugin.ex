defmodule Serum.V2.Plugin do
  @moduledoc """
  A behaviour that all Serum plugin module must implement.

  Experienced Serum users and developers can make their own Serum plugins which
  can extend the functionality of Serum.

  A Serum plugin can...

  - Alter contents of input or output files,
  - Execute arbitrary codes during the project build process,
  - And optionally provide additional Mix tasks.

  In order for a Serum plugin to work, its module must implement these
  callbacks, or the plugin will fail to load.

  - `name/0`
  - `description/0`
  - `version/0`
  - `implements/0`
  - `init/1`
  - `cleanup/1`

  Also, there are a number of other callbacks the plugin modules can optionally
  implement. Read the rest of the documentation for this module to see which
  optional callbacks you can implement and what each callback should do.

  Instead of directly using the `@behaviour` module attribute, you can `use`
  this module for your convenience. Using this module will...

  - Add default implementations of some required callbacks which can be
    overridable:
    - `name/0` - returns the app name specified in `mix.exs`.
    - `version/0` - returns the version specified in `mix.exs`.
    - `init/0` - does nothing and return an empty value (`{}`).
    - `cleanup/0` - does nothing.
  - And require the `Serum.V2.Result` module and make an alias as `Result`.
  """

  alias Serum.V2
  alias Serum.V2.Fragment
  alias Serum.V2.Page
  alias Serum.V2.Post
  alias Serum.V2.PostList
  # alias Serum.V2.Project
  alias Serum.V2.Result
  alias Serum.V2.Template

  @type spec :: module() | {module(), options()}
  @type options :: [only: atom() | [atom()], args: term()]

  @required_msg "You must implement this callback, or the plugin will fail."

  @optional_callbacks [
    build_started: 2,
    build_succeeded: 2,
    build_failed: 3,
    reading_pages: 2,
    reading_posts: 2,
    reading_templates: 2,
    processing_pages: 2,
    processing_posts: 2,
    processing_templates: 2,
    processed_pages: 2,
    processed_posts: 2,
    processed_templates: 2,
    generated_post_lists: 2,
    generating_fragment: 3,
    generated_fragment: 2,
    rendered_pages: 2,
    wrote_files: 2
  ]

  @spec __using__(Macro.t()) :: Macro.t()
  defmacro __using__(_opts) do
    quote do
      require Serum.V2.Result, as: Result

      @behaviour unquote(__MODULE__)

      @impl true
      def name, do: Mix.Project.config()[:app]

      @impl true
      def version, do: Mix.Project.config()[:version]

      @impl true
      def init(_args), do: Result.return()

      @impl true
      def cleanup(_state), do: Result.return()

      defoverridable name: 0, version: 0, init: 1, cleanup: 1
    end
  end

  #
  # Required Callbacks
  #

  @doc """
  Returns the name of the plugin.

  #{@required_msg}
  """
  @callback name() :: binary()

  @doc """
  Returns a short, one-liner description about what the plugin does.

  #{@required_msg}
  """
  @callback description() :: binary()

  @doc """
  Returns the version requirement of Elixir.

  Refer to [this document](https://hexdocs.pm/elixir/Version.html#module-requirements)
  for the string format.

  #{@required_msg}
  """
  @callback version() :: binary()

  @doc """
  Returns a list of optional callbacks which the plugin implements.

  Each list item must be in the form of `{callback_name, arity}`.

  For example, if your plugin implements `build_started/2` and
  `build_succeeded/2`, you must implement this callback so that it returns
  `[build_started: 2, finalizing: 2]`.

  #{@required_msg}
  """
  @callback implements() :: [{atom(), integer()}]

  @doc """
  Called after the plugin is loaded. Do some initialization (e.g. start some
  processes, or create temporary files/directories) here which will be
  persisted across multiple website builds until the plugin is unloaded.

  The returned value will be used as the initial state of the plugin.

  #{@required_msg}
  """
  @callback init(args :: term()) :: Result.t(term())

  @doc """
  Called when the plugin is about to be unloaded. Release or delete any
  resources created by the `init/1` callback here.

  #{@required_msg}
  """
  @callback cleanup(state :: term()) :: Result.t({})

  #
  # Optional Callbacks
  #

  @doc "Called when Serum started building a project."
  # @callback build_started(project :: Project.t(), state :: state) :: Result.t(state)
  @callback build_started(project :: term(), state :: state) :: Result.t(state)
            when state: term()

  @doc "Called when Serum finished building a project successfully."
  # @callback build_succeeded(project :: Project.t(), state :: state) :: Result.t(state)
  @callback build_succeeded(project :: term(), state :: state) :: Result.t(state)
            when state: term()

  @doc "Called when Serum failed to build a project."
  # @callback build_failed(project :: Project.t(), result :: Result.t(term()), state :: state) ::
  @callback build_failed(project :: term(), result :: Result.t(term()), state :: state) ::
              Result.t(state)
            when state: term()

  @doc """
  Called before reading source files for pages.

  A list of paths to input files is given. The implementing plugin may modify
  this list and pass it to the next plugin.
  """
  @callback reading_pages(paths :: [binary()], state :: state) :: Result.t({[binary()], state})
            when state: term()

  @doc """
  Called before reading source files for blog posts.

  A list of paths to input files is given. The implementing plugin may modify
  this list and pass it to the next plugin.
  """
  @callback reading_posts(paths :: [binary()], state :: state) :: Result.t({[binary()], state})
            when state: term()

  @doc """
  Called before reading source files for templates and includes.

  A list of paths to input files is given. The implementing plugin may modify
  this list and pass it to the next plugin.
  """
  @callback reading_templates(paths :: [binary()], state :: state) ::
              Result.t({[binary()], state})
            when state: term()

  @doc """
  Called before Serum parses page sources.

  A list of `Serum.V2.File` structs each with `:src` and `:in_data` information
  is given. The implementing plugin may modify this list and pass it to the
  next plugin.
  """
  @callback processing_pages(files :: [V2.File.t()], state :: state) ::
              Result.t({[V2.File.t()], state})
            when state: term()

  @doc """
  Called before Serum parses blog post sources.

  A list of `Serum.V2.File` structs each with `:src` and `:in_data` information
  is given. The implementing plugin may modify this list and pass it to the
  next plugin.
  """
  @callback processing_posts(files :: [V2.File.t()], state :: state) ::
              Result.t({[V2.File.t()], state})
            when state: term()

  @doc """
  Called before Serum parses template sources.

  A list of `Serum.V2.File` structs each with `:src` and `:in_data` information
  is given. The implementing plugin may modify this list and pass it to the
  next plugin.
  """
  @callback processing_templates(files :: [V2.File.t()], state :: state) ::
              Result.t({[V2.File.t()], state})
            when state: term()

  @doc """
  Called after Serum has processed page sources.

  A list of `Serum.V2.Page` structs is given. The implementing plugin may
  modify this list and pass it to the next plugin.
  """
  @callback processed_pages(pages :: [Page.t()], state :: state) :: Result.t({[Page.t()], state})
            when state: term()

  @doc """
  Called after Serum has processed post sources.

  A list of `Serum.V2.Post` structs is given. The implementing plugin may
  modify this list and pass it to the next plugin.
  """
  @callback processed_posts(pages :: [Post.t()], state :: state) :: Result.t({[Post.t()], state})
            when state: term()

  @doc """
  Called after Serum has processed template sources.

  A list of `Serum.V2.Template` structs is given. The implementing plugin may
  modify this list and pass it to the next plugin.
  """
  @callback processed_templates(templates :: [Template.t()], state :: state) ::
              Result.t({[Template.t()], state})
            when state: term()

  @doc """
  Called after Serum has generated lists of blog posts.

  A list of `Serum.V2.PostList` structs, which are once again grouped by tag,
  is given. The implementing plugin may modify this list and pass it to the
  next plugin.
  """
  @callback generated_post_lists(post_lists :: [[PostList.t()]], state :: state) ::
              Result.t({[[PostList.t()]], state})
            when state: term()

  @doc """
  Called while each `Serum.V2.Fragment` struct is being constructed.

  A HTML tree of the fragment's contents (which is generated by Floki) and the
  metadata of the fragment are given. The implementing plugin may modify the
  HTML tree and pass it to the next plugin.
  """
  @callback generating_fragment(html_tree :: html_tree, metadata :: map(), state :: state) ::
              Result.t({html_tree, state})
            when html_tree: term, state: term

  @doc """
  Called when Serum has generated each `Serum.V2.Fragment` struct.

  An `Serum.V2.Fragment` struct is given. The implementing plugin can modify
  its contents and metadata and pass the updated fragment to the next plugin.
  """
  @callback generated_fragment(fragment :: Fragment.t(), state :: state) ::
              Result.t({Fragment.t(), state})
            when state: term()

  @doc """
  Called after Serum has rendered all pages and before writing them to files.

  A list of `Serum.V2.File` structs each with `:dest` and `:out_data`
  information is given. The implementing plugin may modify this list and pass
  it to the next plugin.
  """
  @callback rendered_pages(files :: [V2.File.t()], state :: state) ::
              Result.t({[V2.File.t()], state})
            when state: term()

  @doc """
  Called after Serum has written all output files to disk.

  A list of `Serum.V2.File` structs each with `:dest` and `:out_data`
  information is given.
  """
  @callback wrote_files(files :: [V2.File.t()], state :: state) :: Result.t(state)
            when state: term()
end
