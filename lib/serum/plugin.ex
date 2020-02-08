defmodule Serum.Plugin do
  @moduledoc """
  A behaviour that all Serum plugin module must implement.

  This module allows experienced Serum users and developers to make their own
  Serum plugins which can extend the functionality of Serum.

  A Serum plugin can...

  - Alter contents of input or output files,
  - Execute arbitrary codes during some stages of site building,
  - And optionally provide extra Mix tasks that extends Serum.

  ## For Plugin Developers

  In order for a Serum plugin to work, you must implement at least these
  four callbacks:

  - `name/0`
  - `version/0`
  - `elixir/0`
  - `serum/0`
  - `description/0`
  - `implements/0`

  Also there are a number of other callbacks you can optionally implement.
  Read the rest of the documentation for this module to see which callbacks
  you can implement and what each callback should do.

  ## For Plugin Users

  To enable Serum plugins, add a `plugins` key to your `serum.exs`(if it does
  not exist), and put names of Serum plugin modules there.

      %{
        plugins: [
          Awesome.Serum.Plugin,
          Great.Serum.Plugin
        ]
      }

  You can also restrict some plugins to run only in specific Mix environments.
  For example, if plugins are configured like the code below, only
  `Awesome.Serum.Plugin` plugin will be loaded when `MIX_ENV` is set to `prod`.

      %{
        plugins: [
          Awesome.Serum.Plugin,
          {Great.Serum.Plugin, only: :dev},
          {Another.Serum.Plugin, only: [:dev, :test]}
        ]
      }

  The order of plugins is important, as Serum will call plugins one by one,
  from the first item to the last one. Therefore these two configurations below
  may produce different results.

  Configuration 1:

      %{
        plugins: [
          Awesome.Serum.Plugin,
          Another.Serum.Plugin
        ]
      }

  Configuration 2:

      %{
        plugins: [
          Another.Serum.Plugin,
          Awesome.Serum.Plugin
        ]
      }
  """

  use Agent
  require Serum.Result, as: Result
  import Serum.V2.Console, only: [put_msg: 2]
  alias Serum.File
  alias Serum.Fragment
  alias Serum.Page
  alias Serum.Plugin.Loader
  alias Serum.Post
  alias Serum.PostList
  alias Serum.Template

  defstruct [:module, :name, :version, :description, :implements, :args]

  @type t :: %__MODULE__{
          module: atom(),
          name: binary(),
          version: binary(),
          description: binary(),
          implements: [atom()],
          args: term()
        }

  @type spec :: atom() | {atom(), plugin_options()}
  @type plugin_options :: [only: atom() | [atom()], args: term()]

  @optional_callbacks [
    build_started: 3,
    reading_pages: 2,
    reading_posts: 2,
    reading_templates: 2,
    processing_page: 2,
    processing_post: 2,
    processing_template: 2,
    processed_page: 2,
    processed_post: 2,
    processed_template: 2,
    processed_list: 2,
    processed_pages: 2,
    processed_posts: 2,
    rendering_fragment: 3,
    rendered_fragment: 2,
    rendered_page: 2,
    wrote_file: 2,
    build_succeeded: 3,
    build_failed: 4,
    finalizing: 3
  ]

  @required_msg "You must implement this callback, or the plugin may fail."

  #
  # Required Callbacks
  #

  @doc """
  Returns the name of the plugin.

  #{@required_msg}
  """
  @callback name() :: binary()

  @doc """
  Returns the version of the plugin.

  The returned version string must follow the semantic versioning scheme.

  #{@required_msg}
  """
  @callback version() :: binary()

  @doc """
  Returns the version requirement of Elixir.

  Refer to [this document](https://hexdocs.pm/elixir/Version.html#module-requirements)
  for the string format.

  #{@required_msg}
  """
  @callback elixir() :: binary()

  @doc """
  Returns the version requirement of Serum.

  Refer to [this document](https://hexdocs.pm/elixir/Version.html#module-requirements)
  for the string format.

  #{@required_msg}
  """
  @callback serum() :: binary()

  @doc """
  Returns the short description of the plugin.

  #{@required_msg}
  """
  @callback description() :: binary()

  @doc """
  Returns a list of optional callbacks which the plugin implements.

  Each list item must be in the form of `{callback_name, arity}`.

  For example, if your plugin implements `build_started/3` and `finalizing/3`,
  you must implement this callback so that it returns `[build_started: 3,
  finalizing: 3]`.

  #{@required_msg}
  """
  @callback implements() :: [{atom(), integer()}]

  #
  # Optional Callbacks
  #

  @doc """
  Called right after the build process has started. Some necessary OTP
  applications or processes should be started here.
  """
  @callback build_started(src :: binary(), dest :: binary(), args :: term()) :: Result.t({})

  @doc """
  Called before reading input files.

  Plugins can manipulate the list of files to be read and pass it to
  the next plugin.
  """
  @callback reading_pages(files :: [binary()], args :: term()) :: Result.t([binary()])

  @doc """
  Called before reading input files.

  Plugins can manipulate the list of files to be read and pass it to
  the next plugin.
  """
  @callback reading_posts(files :: [binary()], args :: term()) :: Result.t([binary()])

  @doc """
  Called before reading input files.

  Plugins can manipulate the list of files to be read and pass it to
  the next plugin.
  """
  @callback reading_templates(files :: [binary()], args :: term()) :: Result.t([binary()])

  @doc """
  Called before Serum processes each input file.

  Plugins can alter the raw contents of input files here.
  """
  @callback processing_page(file :: File.t(), args :: term()) :: Result.t(File.t())

  @doc """
  Called before Serum processes each input file.

  Plugins can alter the raw contents of input files here.
  """
  @callback processing_post(file :: File.t(), args :: term()) :: Result.t(File.t())

  @doc """
  Called before Serum processes each input file.

  Plugins can alter the raw contents of input files here.
  """
  @callback processing_template(file :: File.t(), args :: term()) :: Result.t(File.t())

  @doc """
  Called after Serum has processed each input file and produced
  the resulting struct.

  Plugins can alter the processed contents and metadata here.
  """
  @callback processed_page(page :: Page.t(), args :: term()) :: Result.t(Page.t())

  @doc """
  Called after Serum has processed each input file and produced
  the resulting struct.

  Plugins can alter the processed contents and metadata here.
  """
  @callback processed_post(post :: Post.t(), args :: term()) :: Result.t(Post.t())

  @doc """
  Called after Serum has processed each input file and produced
  the resulting struct.

  Plugins can alter the AST and its metadata here.
  """
  @callback processed_template(template :: Template.t(), args :: term()) :: Result.t(Template.t())

  @doc """
  Called after Serum has processed each input file and produced
  the resulting struct.

  Plugins can alter the processed contents and metadata here.
  """
  @callback processed_list(list :: PostList.t(), args :: term()) :: Result.t(PostList.t())

  @doc "Called after Serum has successfully processed all pages."
  @callback processed_pages(pages :: [Page.t()], args :: term()) :: Result.t([Page.t()])

  @doc "Called after Serum has successfully processed all blog posts."
  @callback processed_posts(posts :: [Post.t()], args :: term()) :: Result.t([Post.t()])

  @doc """
  Called while each fragment is being constructed.

  Plugins can alter the HTML tree of its contents (which is generated by
  Floki). It is recommended to implement this callback if you want to modify
  the HTML document without worrying about breaking it.
  """
  @callback rendering_fragment(html :: Floki.html_tree(), metadata :: map(), args :: term()) ::
              Result.t(Floki.html_tree())

  @doc """
  Called after producing a HTML fragment for each page.

  Plugins can modify the contents and metadata of each fragment here.
  """
  @callback rendered_fragment(frag :: Fragment.t(), args :: term()) :: Result.t(Fragment.t())

  @doc """
  Called when Serum has rendered a full page and it's about to write to an
  output file.

  Plugins can alter the raw contents of the page to be written.
  """
  @callback rendered_page(file :: File.t(), args :: term()) :: Result.t(File.t())

  @doc """
  Called after writing each output to a file.
  """
  @callback wrote_file(file :: File.t(), args :: term()) :: Result.t({})

  @doc """
  Called if the whole build process has finished successfully.
  """
  @callback build_succeeded(src :: binary(), dest :: binary(), args :: term()) :: Result.t({})

  @doc """
  Called if the build process has failed for some reason.
  """
  @callback build_failed(
              src :: binary(),
              dest :: binary(),
              result :: Result.t(term),
              args :: term()
            ) ::
              Result.t({})

  @doc """
  Called right before Serum exits, whether the build has succeeded or not.

  This is the place where you should clean up any temporary resources created
  in `build_started/2` callback.
  """
  @callback finalizing(src :: binary(), dest :: binary(), args :: term()) :: Result.t({})

  #
  # Plugin Consumer Functions
  #

  @doc false
  @spec start_link(any()) :: {:error, any()} | {:ok, pid()}
  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc false
  @spec load_plugins([spec()]) :: Result.t([t()])
  def load_plugins(plugin_specs), do: Loader.load_plugins(plugin_specs)

  @doc false
  @spec show_info([t()]) :: Result.t({})
  def show_info(plugins)
  def show_info([]), do: Result.return()

  def show_info(plugins) do
    Enum.each(plugins, fn p ->
      msg = [
        :bright,
        p.name,
        " v",
        to_string(p.version),
        :reset,
        " (#{module_name(p.module)})\n",
        :light_black,
        p.description
      ]

      put_msg(:plugin, msg)
    end)

    Result.return()
  end

  @spec module_name(atom()) :: binary()
  defp module_name(module) do
    module |> to_string() |> String.replace_prefix("Elixir.", "")
  end
end
