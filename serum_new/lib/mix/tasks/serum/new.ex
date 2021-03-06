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
    `PATH` already exists and is not empty.
  """

  @shortdoc "Creates a new Serum project"

  use Mix.Task
  require Mix.Generator
  import Serum.New
  alias Serum.New.Files
  alias IO.ANSI, as: A

  @elixir_version Version.parse!(System.version())
  @version Mix.Project.config()[:version]
  @options [force: :boolean]

  @impl true
  def run(args)

  def run([ver]) when ver in ["-v", "--version"] do
    Mix.shell().info("Serum installer, version #{@version}")
  end

  def run(args) do
    {options, argv} = OptionParser.parse!(args, strict: @options)

    with [path | _] <- argv,
         {:ok, app_name} <- process_path(path, options[:force] || false) do
      assigns = [
        app_name: app_name,
        mod_name: Macro.camelize(app_name),
        elixir_version: get_version_req(@elixir_version),
        serum_dep: get_serum_dep()
      ]

      if path != "." do
        Mix.Generator.create_directory(path)
      end

      File.cd!(path, fn -> generate_project(path, assigns) end)
    else
      [] ->
        Mix.raise("expected PATH to be given. Run mix help serum.new for help")

      {:error, msg} ->
        Mix.raise(msg)
    end
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

    create_file(".formatter.exs", Files.text(:formatter_exs))
    create_file(".gitignore", Files.template(:gitignore, assigns))
    create_file("mix.exs", Files.template(:mix_exs, assigns))
    create_file("serum.exs", Files.template(:serum_exs, assigns))

    create_file("includes/nav.html.eex", Files.text(:nav_html_eex))
    create_file("templates/base.html.eex", Files.text(:base_html_eex))
    create_file("templates/list.html.eex", Files.text(:list_html_eex))
    create_file("templates/page.html.eex", Files.text(:page_html_eex))
    create_file("templates/post.html.eex", Files.text(:post_html_eex))

    create_file("pages/index.md", Files.text(:index_md))
    create_file("posts/2019-01-01-sample-post.md", Files.text(:sample_post_md))

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
