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
  - `description/0`
  - `implements/0`

  Also there are a number of other callbacks you can optionally implement.
  Read the rest of the documentation for this module to see which callbacks
  you can implement and what each callback should do.

  ## For Plugin Users

  To enable Serum plugins, add a `plugins` key to your `serum.exs`(if it does
  not exist), and put names of Serum plugin modules there.

  The order of plugins is important, as Serum will call plugins one by one, from
  the first item to the last one. Therefore these two configurations below may
  produce different results.

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

  alias Serum.Result
  alias Serum.File
  alias Serum.Fragment
  alias Serum.Page
  alias Serum.Post
  alias Serum.Template
  alias Serum.PostList

  @optional_callbacks [
    build_started: 2,
    reading_pages: 1,
    reading_posts: 1,
    reading_templates: 1,
    processing_page: 1,
    processing_post: 1,
    processing_template: 1,
    processed_page: 1,
    processed_post: 1,
    processed_template: 1,
    processed_list: 1,
    rendered_fragment: 1,
    rendered_page: 1,
    wrote_file: 1,
    build_succeeded: 2,
    build_failed: 3,
    finalizing: 2
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
  Returns the short description of the plugin.

  #{@required_msg}
  """
  @callback description() :: binary()

  @doc """
  Returns a list of optional callbacks which the plugin implements.

  For example, if your plugin implements `build_started/2` and `finalizing/2`,
  you must implement this callback so that it returns `[:build_started,
  :finalizing]`.

  #{@required_msg}
  """
  @callback implements() :: [atom()]

  #
  # Optional Callbacks
  #

  @doc """
  Called right after the build process has started. Some necessary OTP
  applications or processes should be started here.
  """
  @callback build_started(src :: binary(), dest :: binary()) :: Result.t()

  @doc """
  Called before reading input files.

  Plugins can manipulate the list of files to be read and pass it to
  the next plugin.
  """
  @callback reading_pages(files :: [binary()]) :: Result.t([binary()])

  @doc """
  Called before reading input files.

  Plugins can manipulate the list of files to be read and pass it to
  the next plugin.
  """
  @callback reading_posts(files :: [binary()]) :: Result.t([binary()])

  @doc """
  Called before reading input files.

  Plugins can manipulate the list of files to be read and pass it to
  the next plugin.
  """
  @callback reading_templates(files :: [binary()]) :: Result.t([binary()])

  @doc """
  Called before Serum processes each input file.

  Plugins can alter the raw contents of input files here.
  """
  @callback processing_page(file :: File.t()) :: Result.t(File.t())

  @doc """
  Called before Serum processes each input file.

  Plugins can alter the raw contents of input files here.
  """
  @callback processing_post(file :: File.t()) :: Result.t(File.t())

  @doc """
  Called before Serum processes each input file.

  Plugins can alter the raw contents of input files here.
  """
  @callback processing_template(file :: File.t()) :: Result.t(File.t())

  @doc """
  Called after Serum has processed each input file and produced
  the resulting struct.

  Plugins can alter the processed contents and metadata here.
  """
  @callback processed_page(page :: Page.t()) :: Result.t(Page.t())

  @doc """
  Called after Serum has processed each input file and produced
  the resulting struct.

  Plugins can alter the processed contents and metadata here.
  """
  @callback processed_post(post :: Post.t()) :: Result.t(Post.t())

  @doc """
  Called after Serum has processed each input file and produced
  the resulting struct.

  Plugins can alter the AST and its metadata here.
  """
  @callback processed_template(template :: Template.t()) :: Result.t(Template.t())

  @doc """
  Called after Serum has processed each input file and produced
  the resulting struct.

  Plugins can alter the processed contents and metadata here.
  """
  @callback processed_list(list :: PostList.t()) :: Result.t(PostList.t())

  @doc """
  Called after producing a HTML fragment for each page.

  Plugins can modify the contents and metadata of each fragment here.
  """
  @callback rendered_fragment(frag :: Fragment.t()) :: Result.t(Fragment.t())

  @doc """
  Called when Serum has rendered a full page and it's about to write to an
  output file.

  Plugins can alter the raw contents of the page to be written.
  """
  @callback rendered_page(file :: File.t()) :: Result.t(File.t())

  @doc """
  Called after writing each output to a file.
  """
  @callback wrote_file(file :: File.t()) :: Result.t()

  @doc """
  Called if the whole build process has finished successfully.
  """
  @callback build_succeeded(src :: binary(), dest :: binary()) :: Result.t()

  @doc """
  Called if the build process has failed for some reason.
  """
  @callback build_failed(src :: binary(), dest :: binary(), result :: Result.t() | Result.t(term)) ::
              Result.t()

  @doc """
  Called right before Serum exits, whether the build has succeeded or not.

  This is the place where you should clean up any temporary resources created
  in `build_started/2` callback.
  """
  @callback finalizing(src :: binary(), dest :: binary()) :: Result.t()
end
