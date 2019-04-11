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
  require Serum.Util
  import Serum.Util
  alias Serum.File
  alias Serum.Fragment
  alias Serum.Page
  alias Serum.Post
  alias Serum.PostList
  alias Serum.Result
  alias Serum.Template

  defstruct [:module, :name, :version, :description, :implements]

  @type t :: %__MODULE__{
          module: atom(),
          name: binary(),
          version: binary(),
          description: binary(),
          implements: [atom()]
        }

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

  @serum_version Version.parse!(Mix.Project.config()[:version])
  @elixir_version Version.parse!(System.version())
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

  #
  # Plugin Consumer Functions
  #

  @doc false
  @spec start_link(any()) :: {:error, any()} | {:ok, pid()}
  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  @doc false
  @spec load_plugins([atom()]) :: Result.t([t()])
  def load_plugins(modules) do
    modules
    |> Enum.uniq()
    |> Enum.map(&make_plugin/1)
    |> Result.aggregate_values(:load_plugins)
    |> case do
      {:ok, plugins} ->
        update_agent(plugins)

        {:ok, plugins}

      {:error, _} = error ->
        error
    end
  end

  @spec make_plugin(atom()) :: Result.t(t())
  defp make_plugin(module) do
    name = module.name()
    version = Version.parse!(module.version())
    elixir = module.elixir()
    serum = module.serum()

    unless Version.match?(@elixir_version, elixir) do
      warn(
        "The plugin \"#{name}\" is not compatible with " <>
          "the current version of Elixir(#{@elixir_version}). " <>
          "This plugin may not work as intended."
      )
    end

    unless Version.match?(@serum_version, serum) do
      warn(
        "The plugin \"#{name}\" is not compatible with " <>
          "the current version of Serum(#{@serum_version}). " <>
          "This plugin may not work as intended."
      )
    end

    plugin = %__MODULE__{
      module: module,
      name: name,
      version: version,
      description: module.description(),
      implements: module.implements()
    }

    {:ok, plugin}
  rescue
    exception ->
      ex_name = module_name(exception.__struct__)
      ex_msg = Exception.message(exception)
      msg = "#{ex_name} while loading plugin (module: #{module}): #{ex_msg}"

      {:error, msg}
  end

  @spec update_agent([t()]) :: :ok
  defp update_agent(plugins) do
    plugins
    |> Enum.map(fn plugin -> Enum.map(plugin.implements, &{&1, plugin}) end)
    |> List.flatten()
    |> Enum.each(fn {fun, plugin} ->
      Agent.update(__MODULE__, fn state ->
        Map.put(state, fun, [plugin | state[fun] || []])
      end)
    end)

    Agent.update(__MODULE__, fn state ->
      for {key, value} <- state, into: %{}, do: {key, Enum.reverse(value)}
    end)
  end

  @doc false
  @spec build_started(src :: binary(), dest :: binary()) :: Result.t()
  def build_started(src, dest) do
    call_action(:build_started, [src, dest])
  end

  @doc false
  @spec reading_pages(files :: [binary()]) :: Result.t([binary()])
  def reading_pages(files) do
    call_function(:reading_pages, [files])
  end

  @doc false
  @spec reading_posts(files :: [binary()]) :: Result.t([binary()])
  def reading_posts(files) do
    call_function(:reading_posts, [files])
  end

  @doc false
  @spec reading_templates(files :: [binary()]) :: Result.t([binary()])
  def reading_templates(files) do
    call_function(:reading_templates, [files])
  end

  @doc false
  @spec processing_page(file :: File.t()) :: Result.t(File.t())
  def processing_page(file) do
    call_function(:processing_page, [file])
  end

  @doc false
  @spec processing_post(file :: File.t()) :: Result.t(File.t())
  def processing_post(file) do
    call_function(:processing_post, [file])
  end

  @doc false
  @spec processing_template(file :: File.t()) :: Result.t(File.t())
  def processing_template(file) do
    call_function(:processing_template, [file])
  end

  @doc false
  @spec processed_page(page :: Page.t()) :: Result.t(Page.t())
  def processed_page(page) do
    call_function(:processed_page, [page])
  end

  @doc false
  @spec processed_post(post :: Post.t()) :: Result.t(Post.t())
  def processed_post(post) do
    call_function(:processed_post, [post])
  end

  @doc false
  @spec processed_template(template :: Template.t()) :: Result.t(Template.t())
  def processed_template(template) do
    call_function(:processed_template, [template])
  end

  @doc false
  @spec processed_list(list :: PostList.t()) :: Result.t(PostList.t())
  def processed_list(list) do
    call_function(:processed_list, [list])
  end

  @doc false
  @spec rendered_fragment(frag :: Fragment.t()) :: Result.t(Fragment.t())
  def rendered_fragment(frag) do
    call_function(:rendered_fragment, [frag])
  end

  @doc false
  @spec rendered_page(file :: File.t()) :: Result.t(File.t())
  def rendered_page(file) do
    call_function(:rendered_page, [file])
  end

  @doc false
  @spec wrote_file(file :: File.t()) :: Result.t()
  def wrote_file(file) do
    call_action(:wrote_file, [file])
  end

  @doc false
  @spec build_succeeded(src :: binary(), dest :: binary()) :: Result.t()
  def build_succeeded(src, dest) do
    call_action(:build_succeeded, [src, dest])
  end

  @doc false
  @spec build_failed(src :: binary(), dest :: binary(), result :: Result.t() | Result.t(term)) ::
          Result.t()
  def build_failed(src, dest, result) do
    call_action(:build_failed, [src, dest, result])
  end

  @doc false
  @spec finalizing(src :: binary(), dest :: binary()) :: Result.t()
  def finalizing(src, dest) do
    call_action(:finalizing, [src, dest])
  end

  @spec call_action(atom(), [term()]) :: Result.t()
  defp call_action(fun, args) do
    __MODULE__
    |> Agent.get(&(&1[fun] || []))
    |> do_call_action(fun, args)
  end

  @spec do_call_action([t()], atom(), [term()]) :: Result.t()
  defp do_call_action(plugins, fun, args)
  defp do_call_action([], _fun, _args), do: :ok

  defp do_call_action([plugin | plugins], fun, args) do
    case apply(plugin.module, fun, args) do
      :ok ->
        do_call_action(plugins, fun, args)

      {:error, _} = error ->
        error

      term ->
        message =
          "#{module_name(plugin.module)}.#{fun} returned " <>
            "an unexpected value: #{inspect(term)}"

        {:error, message}
    end
  rescue
    exception -> handle_exception(exception, plugin.module, fun)
  end

  @spec call_function(atom(), [term()]) :: Result.t(term())
  defp call_function(fun, [arg | args]) do
    __MODULE__
    |> Agent.get(&(&1[fun] || []))
    |> do_call_function(fun, args, arg)
  end

  @spec do_call_function([t()], atom(), [term()], term()) :: Result.t(term())
  defp do_call_function(plugins, fun, args, acc)
  defp do_call_function([], _fun, _args, acc), do: {:ok, acc}

  defp do_call_function([plugin | plugins], fun, args, acc) do
    case apply(plugin.module, fun, [acc | args]) do
      {:ok, new_acc} ->
        do_call_function(plugins, fun, args, new_acc)

      {:error, _} = error ->
        error

      term ->
        message =
          "#{module_name(plugin.module)}.#{fun} returned " <>
            "an unexpected value: #{inspect(term)}"

        {:error, message}
    end
  rescue
    exception -> handle_exception(exception, plugin.module, fun)
  end

  @spec handle_exception(Exception.t(), atom(), atom()) :: Result.t()
  defp handle_exception(exception, module, fun) do
    ex_name = module_name(exception.__struct__)
    ex_msg = Exception.message(exception)
    msg = "#{ex_name} at #{module_name(module)}.#{fun}: #{ex_msg}"

    {:error, msg}
  end

  @spec module_name(atom()) :: binary()
  defp module_name(module) do
    module |> to_string() |> String.replace_prefix("Elixir.", "")
  end
end
