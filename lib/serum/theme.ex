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
  require Serum.Result, as: Result
  import Serum.V2.Console, only: [put_err: 2]
  alias Serum.Error

  defstruct module: nil,
            name: "",
            description: "",
            author: "",
            legal: "",
            version: Version.parse!("0.0.0")

  @type t :: %__MODULE__{
          module: module() | nil,
          name: binary(),
          description: binary(),
          author: binary(),
          legal: binary(),
          version: Version.t()
        }

  @serum_version Version.parse!(Mix.Project.config()[:version])

  #
  # Callbacks
  #

  @doc "Returns the theme name."
  @callback name() :: binary()

  @doc "Returns a short descriptive text about the theme."
  @callback description() :: binary()

  @doc "Returns information about the theme author."
  @callback author() :: binary()

  @doc "Returns the legal information about the theme, such as license."
  @callback legal() :: binary()

  @doc """
  Returns the theme version.

  The returned value must follow the semantic versioning scheme.
  """
  @callback version() :: binary()

  @doc """
  Returns the required version of Serum.

  Read the "Requirements" section in the documentation for `Version` module
  for more information about version requirement format.
  """
  @callback serum() :: binary()

  @doc """
  Returns a list of paths to include files.

  All paths in the list must end with `".html.eex"`. Anything that does not end
  with `".html.eex"` will be ignored.

  ## Example Return Value

      [
        "/path/to/theme/priv/includes/nav.html.eex",
        "/path/to/theme/priv/includes/sidebar.html.eex",
        "/path/to/theme/priv/includes/footer.html.eex"
      ]
  """
  @callback get_includes() :: [binary()]

  @doc """
  Returns a list of paths to template files.

  All paths in the list must end with `".html.eex"`. Anything that does not end
  with `".html.eex"` will be ignored.

  ## Example Return Value

      [
        "/path/to/theme/priv/templates/base.html.eex",
        "/path/to/theme/priv/templates/list.html.eex",
        "/path/to/theme/priv/templates/post.html.eex"
      ]
  """
  @callback get_templates() :: [binary()]

  @doc """
  Returns a path to the assets directory.

  All files in the directory pointed by the returned value will be copied to
  the destination assets directory using `File.cp_r/2`.

  This callback may return `false` to indicate that no asset will be copied.
  """
  @callback get_assets() :: binary() | false

  #
  # Theme Consumer Functions
  #

  @doc false
  @spec start_link(any()) :: Agent.on_start()
  def start_link(_) do
    Agent.start_link(fn -> nil end, name: __MODULE__)
  end

  @doc false
  @spec load(module() | nil) :: Result.t(t())
  def load(module_or_nil)

  def load(nil) do
    Agent.update(__MODULE__, fn _ -> nil end)
    Result.return(%__MODULE__{})
  end

  def load(module) do
    case make_theme(module) do
      {:ok, theme} ->
        Agent.update(__MODULE__, fn _ -> theme end)
        Result.return(theme)

      {:error, %Error{}} = error ->
        error
    end
  end

  @spec make_theme(module()) :: Result.t(t())
  defp make_theme(module) do
    name = module.name()
    version = Version.parse!(module.version())

    validate_serum_version(name, module.serum())

    Result.return(%__MODULE__{
      module: module,
      name: name,
      description: module.description(),
      author: module.author(),
      legal: module.legal(),
      version: version
    })
  rescue
    exception -> Result.fail(Exception: [exception, __STACKTRACE__])
  end

  @spec validate_serum_version(binary(), Version.requirement()) :: Result.t({})
  defp validate_serum_version(name, requirement) do
    if Version.match?(@serum_version, requirement) do
      Result.return()
    else
      msg =
        "The theme \"#{name}\" is not compatible with " <>
          "the current version of Serum(#{@serum_version}). " <>
          "This theme may not work as intended."

      put_err(:warn, msg)
    end
  end

  @doc false
  @spec get_includes() :: Result.t(%{optional(binary()) => binary()})
  def get_includes do
    case Agent.get(__MODULE__, & &1) do
      %__MODULE__{} = theme -> do_get_includes(theme)
      nil -> Result.return(%{})
    end
  end

  @spec do_get_includes(t()) :: Result.t(%{optional(binary()) => binary()})
  defp do_get_includes(%__MODULE__{module: module}) do
    case get_list(module, :get_includes, []) do
      {:ok, paths} ->
        result =
          paths
          |> Enum.filter(&String.ends_with?(&1, ".html.eex"))
          |> Enum.map(&{Path.basename(&1, ".html.eex"), &1})
          |> Map.new()

        Result.return(result)

      {:error, %Error{}} = error ->
        error
    end
  end

  @doc false
  @spec get_templates() :: Result.t(%{optional(binary()) => binary()})
  def get_templates do
    case Agent.get(__MODULE__, & &1) do
      %__MODULE__{} = theme -> do_get_templates(theme)
      nil -> Result.return(%{})
    end
  end

  @spec do_get_templates(t()) :: Result.t(%{optional(binary()) => binary()})
  defp do_get_templates(%__MODULE__{module: module}) do
    case get_list(module, :get_templates, []) do
      {:ok, paths} ->
        result =
          paths
          |> Enum.map(&{Path.basename(&1, ".html.eex"), &1})
          |> Enum.filter(&String.ends_with?(elem(&1, 1), ".html.eex"))
          |> Map.new()

        Result.return(result)

      {:error, %Error{}} = error ->
        error
    end
  end

  @spec get_list(atom(), atom(), list()) :: Result.t([binary()])
  defp get_list(module, fun, args) do
    Result.run do
      paths <- call_function(module, fun, args)
      check_list_type(paths, "#{module_name(module)}.#{fun}: ")

      Result.return(paths)
    end
  end

  @spec check_list_type(term(), binary()) :: Result.t({})
  defp check_list_type(maybe_list, prefix)
  defp check_list_type([], _), do: Result.return()

  defp check_list_type([x | xs], prefix) when is_binary(x) do
    check_list_type(xs, prefix)
  end

  defp check_list_type([x | _xs], prefix) do
    msg = "#{prefix} expected a list of strings, got: #{inspect(x)} in the list"

    Result.fail(Simple: [msg])
  end

  defp check_list_type(x, prefix) do
    msg = "#{prefix}: expected a list of strings, got: #{inspect(x)}"

    Result.fail(Simple: [msg])
  end

  @doc false
  @spec get_assets() :: Result.t(binary() | false)
  def get_assets do
    case Agent.get(__MODULE__, & &1) do
      %__MODULE__{} = theme -> do_get_assets(theme)
      nil -> {:ok, false}
    end
  end

  @spec do_get_assets(t()) :: Result.t(binary() | false)
  defp do_get_assets(%__MODULE__{module: module}) do
    case call_function(module, :get_assets, []) do
      {:ok, path} when is_binary(path) ->
        validate_assets_dir(path)

      {:ok, false} ->
        Result.return(false)

      {:ok, x} ->
        mod_name = module_name(module)
        msg = "#{mod_name}.get_assets: expected a string, got: #{inspect(x)}"

        Result.fail(Simple: [msg])

      {:error, %Error{}} = error ->
        error
    end
  end

  @spec validate_assets_dir(binary()) :: Result.t(binary())
  defp validate_assets_dir(path) do
    case File.stat(path) do
      {:ok, %File.Stat{type: :directory}} -> Result.return(path)
      {:ok, %File.Stat{}} -> Result.fail(POSIX: [:enotdir], file: %Serum.File{src: path})
      {:error, reason} -> Result.fail(POSIX: [reason], file: %Serum.File{src: path})
    end
  end

  @spec call_function(atom(), atom(), list()) :: Result.t(term())
  defp call_function(module, fun, args) do
    Result.return(apply(module, fun, args))
  rescue
    exception -> Result.fail(Exception: [exception, __STACKTRACE__])
  end

  @spec module_name(atom()) :: binary()
  defp module_name(module) do
    module |> to_string() |> String.replace_prefix("Elixir.", "")
  end
end
