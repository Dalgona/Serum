defmodule Mix.Tasks.Serum.New.Theme do
  @moduledoc """
  Creates a new Serum theme project.

      mix serum.new.theme [--force] PATH

  A new Serum theme project will be created at the given `PATH`. `PATH` cannot
  be omitted and it must start with a lowercase ASCII letter, followed by zero
  or more lowercase ASCII letters, digits, or underscores.

  This task will fail if `PATH` already exists and is not empty. This behavior
  will be overridden if the task is executed with a `--force` option.

  ## Required Argument

  - `PATH`: A path where the new Serum theme project will be created.

  ## Options

  - `--force` (boolean): Forces creation of the new Serum theme project even if
    `PATH` already exists and is not empty.
  """

  @shortdoc "Creates a new Serum theme project"

  use Mix.Task
  require Mix.Generator
  import Serum.New
  alias Serum.New.Files

  @elixir_version Version.parse!(System.version())
  @version Version.parse!(Mix.Project.config()[:version])
  @options [force: :boolean]

  @impl true
  def run(args) do
    {options, argv} = OptionParser.parse!(args, strict: @options)

    with [path | _] <- argv,
         {:ok, app_name} <- process_path(path, options[:force] || false) do
      assigns = [
        orig_app_name: app_name,
        orig_mod_name: Macro.camelize(app_name),
        app_name: "serum_theme_" <> app_name,
        mod_name: "Serum.Themes." <> Macro.camelize(app_name),
        elixir_version: get_version_req(@elixir_version),
        serum_version: get_version_req(@version),
        serum_dep: get_serum_dep()
      ]

      if path != "." do
        Mix.Generator.create_directory(path)
      end

      File.cd!(path, fn -> generate_project(assigns) end)
    else
      [] ->
        Mix.raise("expected PATH to be given. Run mix help serum.new for help")

      {:error, msg} ->
        Mix.raise(msg)
    end
  end

  @spec generate_project(keyword()) :: :ok
  defp generate_project(assigns) do
    [
      "lib/serum/themes",
      "priv/includes",
      "priv/templates",
      "priv/assets"
    ]
    |> Enum.each(&Mix.Generator.create_directory/1)

    create_file(".formatter.exs", Files.text(:formatter_exs))
    create_file(".gitignore", Files.template(:gitignore, assigns))
    create_file("mix.exs", Files.template(:mix_exs, assigns))

    create_file(
      "lib/serum/themes/#{assigns[:orig_app_name]}.ex",
      Files.template(:theme_module, assigns)
    )

    create_file("priv/templates/base.html.eex", Files.text(:base_html_eex))
    create_file("priv/templates/list.html.eex", Files.text(:list_html_eex))
    create_file("priv/templates/page.html.eex", Files.text(:page_html_eex))
    create_file("priv/templates/post.html.eex", Files.text(:post_html_eex))
    create_file("priv/includes/nav.html.eex", Files.text(:nav_html_eex))
  end
end
