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
  alias Mix.Generator, as: MixGen

  @version Mix.Project.config()[:version]

  @options [
    force: :boolean
  ]

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
          serum_dep: get_serum_dep(Mix.env())
        ]

        if path != "." do
          MixGen.create_directory(path)
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
    |> Enum.each(&MixGen.create_directory/1)

    create_file = &MixGen.create_file(&1, &2, force: true)

    create_file.(".formatter.exs", formatter_exs_text())
    create_file.(".gitignore", gitignore_template(assigns))
    create_file.("mix.exs", mix_exs_template(assigns))
    create_file.("serum.json", serum_json_template(assigns))

    create_file.("includes/nav.html.eex", nav_html_eex_text())
    create_file.("templates/base.html.eex", base_html_eex_text())
    create_file.("templates/list.html.eex", list_html_eex_text())
    create_file.("templates/page.html.eex", page_html_eex_text())
    create_file.("templates/post.html.eex", post_html_eex_text())

    create_file.("pages/index.md", index_md_text())

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

  priv_dir = :code.priv_dir(:serum_new)
  get_priv = fn path -> File.read!("#{priv_dir}/#{path}") end

  # formatter_exs_text/0
  MixGen.embed_text(:formatter_exs, get_priv.("formatter.exs"))

  # gitignore_template/1
  MixGen.embed_template(:gitignore, get_priv.("gitignore.eex"))

  # mix_exs_template/1
  MixGen.embed_template(:mix_exs, get_priv.("mix.exs.eex"))

  # serum_json_template/1
  MixGen.embed_template(:serum_json, get_priv.("serum.json.eex"))

  # nav_html_eex_text/0
  MixGen.embed_text(:nav_html_eex, get_priv.("includes/nav.html.eex"))

  # base_html_eex_text/0
  MixGen.embed_text(:base_html_eex, get_priv.("templates/base.html.eex"))

  # list_html_eex_text/0
  MixGen.embed_text(:list_html_eex, get_priv.("templates/list.html.eex"))

  # page_html_eex_text/0
  MixGen.embed_text(:page_html_eex, get_priv.("templates/page.html.eex"))

  # post_html_eex_text/0
  MixGen.embed_text(:post_html_eex, get_priv.("templates/post.html.eex"))

  # index_md_text/0
  MixGen.embed_text(:index_md, get_priv.("pages/index.md"))
end
