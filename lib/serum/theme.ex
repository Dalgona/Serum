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
  import Serum.IOProxy, only: [put_err: 2]
  alias Serum.Result

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

  Each path in the list must end with one of these: `"/base.html.eex"`,
  `"/list.html.eex"`, `"/page.html.eex"`, and `"/post.html.eex"`. Anything else
  will be ignored.

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

    {:ok, %__MODULE__{}}
  end

  def load(module) do
    case make_theme(module) do
      {:ok, theme} ->
        Agent.update(__MODULE__, fn _ -> theme end)

        {:ok, theme}

      {:error, _} = error ->
        error
    end
  end

  @spec make_theme(module()) :: Result.t(t())
  defp make_theme(module) do
    name = module.name()
    version = Version.parse!(module.version())

    validate_serum_version(name, module.serum())

    result = %__MODULE__{
      module: module,
      name: name,
      description: module.description(),
      author: module.author(),
      legal: module.legal(),
      version: version
    }

    {:ok, result}
  rescue
    exception ->
      ex_name = module_name(exception.__struct__)
      ex_msg = Exception.message(exception)
      mod_name = module_name(module)
      msg = "#{ex_name} while loading theme (module: #{mod_name}): #{ex_msg}"

      {:error, msg}
  end

  @spec validate_serum_version(binary(), Version.requirement()) :: :ok
  defp validate_serum_version(name, requirement) do
    if Version.match?(@serum_version, requirement) do
      :ok
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
      nil -> {:ok, %{}}
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

        {:ok, result}

      {:error, _} = error ->
        error
    end
  end

  @doc false
  @spec get_templates() :: Result.t(%{optional(binary()) => binary()})
  def get_templates do
    case Agent.get(__MODULE__, & &1) do
      %__MODULE__{} = theme -> do_get_templates(theme)
      nil -> {:ok, %{}}
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

        {:ok, result}

      {:error, _} = error ->
        error
    end
  end

  @spec get_list(atom(), atom(), list()) :: Result.t([binary()])
  defp get_list(module, fun, args) do
    with {:ok, paths} <- call_function(module, fun, args),
         :ok <- check_list_type(paths) do
      {:ok, paths}
    else
      {:error, _} = error ->
        error

      {:bad, x} ->
        callee = "#{module_name(module)}.#{fun}"
        msg = "#{callee}: expected a list of strings, got: #{inspect(x)}"

        {:error, msg}

      {:bad_item, x} ->
        callee = "#{module_name(module)}.#{fun}"
        msg = "#{callee} expected a list of strings, got: #{inspect(x)} in the list"

        {:error, msg}
    end
  end

  @spec check_list_type(term()) :: :ok | {:bad, term()} | {:bad_item, term()}
  defp check_list_type(maybe_list)
  defp check_list_type([]), do: :ok
  defp check_list_type([x | xs]) when is_binary(x), do: check_list_type(xs)
  defp check_list_type([x | _xs]), do: {:bad_item, x}
  defp check_list_type(x), do: {:bad, x}

  @doc false
  @spec get_assets() :: Result.t(binary() | false)
  def get_assets do
    case Agent.get(__MODULE__, & &1) do
      %__MODULE__{} = theme -> get_assets(theme)
      nil -> {:ok, false}
    end
  end

  @spec get_assets(t()) :: Result.t(binary() | false)
  defp get_assets(%__MODULE__{module: module}) do
    case call_function(module, :get_assets, []) do
      {:ok, path} when is_binary(path) ->
        do_get_assets(path)

      {:ok, false} ->
        {:ok, false}

      {:error, _} = error ->
        error

      x ->
        mod_name = module_name(module)
        msg = "#{mod_name}.get_assets: expected a string, got: #{inspect(x)}"

        {:error, msg}
    end
  end

  @spec do_get_assets(binary()) :: Result.t(binary())
  defp do_get_assets(path) do
    case File.stat(path) do
      {:ok, %File.Stat{type: :directory}} -> {:ok, path}
      {:ok, %File.Stat{}} -> {:error, {:enotdir, path, 0}}
      {:error, reason} -> {:error, {reason, path, 0}}
    end
  end

  @spec call_function(atom(), atom(), list()) :: Result.t(term())
  defp call_function(module, fun, args) do
    {:ok, apply(module, fun, args)}
  rescue
    exception ->
      ex_name = module_name(exception.__struct__)
      ex_msg = Exception.message(exception)
      mod_name = module_name(module)
      msg = "#{ex_name} from #{mod_name}.#{fun}: #{ex_msg}"

      {:error, msg}
  end

  @spec module_name(atom()) :: binary()
  defp module_name(module) do
    module |> to_string() |> String.replace_prefix("Elixir.", "")
  end
end
