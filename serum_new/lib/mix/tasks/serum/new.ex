defmodule Mix.Tasks.Serum.New do
  @moduledoc """
  Creates a new Serum project.

      mix serum.new [--force] PATH

  A new Serum project will be created at the given `PATH`. `PATH` cannot be
  omitted and it must start with a lowercase ASCII letter, followed by zero
  or more lowercase ASCII letters, digits, or underscores.

  This task will fail if `PATH` already exists and is not empty. This behavior
  will be overridden if the task is executed with a `--force` option.

  ## Required Argument

  - `PATH`: A path where the new Serum project will be created.

  ## Options

  - `--force` (boolean): Forces creation of the new Serum project even if
    `PATH` is not empty.
  """

  @shortdoc "Creates a new Serum project"

  use Mix.Task
  require Mix.Generator
  alias Mix.Generator, as: MixGen

  @options [
    force: :boolean
  ]

  @impl true
  def run(args) do
    {options, argv} = OptionParser.parse!(args, strict: @options)

    case argv do
      [] ->
        Mix.raise("expected PATH to be given. Run mix help serum.new for help")

      [path | _] ->
        force? = options[:force] || false
        :ok = check_path!(path, force?)
        app_name = Path.basename(Path.expand(path))
        :ok = check_app_name!(app_name)

        assigns = [
          app_name: app_name,
          mod_name: Macro.camelize(app_name),
          elixir_version: get_version!()
        ]

        if path != "." do
          MixGen.create_directory(path)
        end

        File.cd!(path, fn -> generate_project(path, assigns) end)
    end

    # Things to implement:
    # - After all checks has passed,
    #   - Create directory structure
    #   - Create files
    #   - Print completion message
  end

  @spec check_path!(binary(), boolean()) :: :ok | no_return()
  defp check_path!(path, force?)
  defp check_path!(_path, true), do: :ok

  defp check_path!(path, false) do
    if File.exists?(path) do
      case File.ls!(path) do
        [] ->
          :ok

        [_ | _] ->
          Mix.raise(
            "#{path} already exists and is not empty. " <>
              "Try again with a --force option to override"
          )
      end
    else
      :ok
    end
  end

  @spec check_app_name!(binary()) :: :ok | no_return()
  defp check_app_name!(app_name) do
    if app_name =~ ~r/^[a-z][a-z0-9_]*$/ do
      :ok
    else
      Mix.raise(
        "PATH must start with a lowercase ASCII letter, " <>
          "followed by zero or more lowercase ASCII letters, digits, " <>
          "or underscores. Got: #{inspect(app_name)}"
      )
    end
  end

  @spec get_version!() :: binary()
  defp get_version! do
    ver = Version.parse!(System.version())

    pre_release =
      case ver.pre do
        [] -> ""
        [x | _xs] -> "-#{x}"
      end

    "#{ver.major}.#{ver.minor}#{pre_release}"
  end

  @spec generate_project(binary(), keyword()) :: :ok
  defp generate_project(path, assigns) do
    Mix.raise("not implemented\npath: #{inspect(path)}\nassigns: #{inspect(assigns)}")
  end
end
