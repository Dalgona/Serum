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
  alias IO.ANSI, as: A
  alias Serum.New.Files

  @version Mix.Project.config()[:version]
  @mix_env Mix.env()
  @options [force: :boolean]

  @impl true
  def run(args)

  def run([ver]) when ver in ["-v", "--version"] do
    Mix.shell().info("Serum installer, version #{@version}")
  end

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
          elixir_version: get_elixir_version!(),
          serum_dep: get_serum_dep(@mix_env)
        ]

        if path != "." do
          Mix.Generator.create_directory(path)
        end

        File.cd!(path, fn -> generate_project(path, assigns) end)
    end
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

  @spec get_elixir_version!() :: binary()
  defp get_elixir_version! do
    ver = Version.parse!(System.version())

    pre_release =
      case ver.pre do
        [] -> ""
        [x | _xs] -> "-#{x}"
      end

    "#{ver.major}.#{ver.minor}#{pre_release}"
  end

  @spec get_serum_dep(atom()) :: binary()
  defp get_serum_dep(env)

  defp get_serum_dep(:prod) do
    ~s({:serum, "~> #{@version}"})
  end

  defp get_serum_dep(_) do
    ~s({:serum, path: "#{Path.expand(Path.join(File.cwd!(), ".."))}"})
  end

  @spec generate_project(binary(), keyword()) :: :ok
  defp generate_project(path, assigns) do
    [
      "assets/css",
      "assets/images",
      "assets/js",
      "includes",
      "media",
      "pages",
      "posts",
      "templates"
    ]
    |> Enum.each(&Mix.Generator.create_directory/1)

    create_file = &Mix.Generator.create_file(&1, &2, force: true)

    create_file.(".formatter.exs", Files.text(:formatter_exs))
    create_file.(".gitignore", Files.template(:gitignore, assigns))
    create_file.("mix.exs", Files.template(:mix_exs, assigns))
    create_file.("serum.exs", Files.template(:serum_exs, assigns))

    create_file.("includes/nav.html.eex", Files.text(:nav_html_eex))
    create_file.("templates/base.html.eex", Files.text(:base_html_eex))
    create_file.("templates/list.html.eex", Files.text(:list_html_eex))
    create_file.("templates/page.html.eex", Files.text(:page_html_eex))
    create_file.("templates/post.html.eex", Files.text(:post_html_eex))

    create_file.("pages/index.md", Files.text(:index_md))

    cd =
      case path do
        "." -> ""
        _ -> "cd #{path}\n    "
      end

    """

    #{A.bright()}Successfully created a new Serum project!#{A.reset()}
    To test your new project, start the Serum development server:

        #{cd}mix deps.get
        mix serum.server [--port PORT]

    Run "mix help serum" for more Serum tasks.
    """
    |> String.trim_trailing()
    |> Mix.shell().info()
  end
end
