defmodule Serum.Init do
  @moduledoc """
  This module contains functions required to initialize a new Serum project.
  """

  import Serum.Util
  alias Serum.Payload
  alias Serum.Result

  @doc """
  Initializes a new Serum project into the given directory `dir`.

  This function will create a minimal required directory structure, and
  generate metadata files and templates.
  """
  @spec init(binary, boolean) :: Result.t()
  def init(dir, force?) do
    with :ok <- check_dir(dir, force?),
         :ok <- create_dir(dir) do
      files = [
        create_info(dir),
        create_index(dir),
        create_templates(dir),
        create_gitignore(dir)
      ]

      files
      |> List.flatten()
      |> Enum.map(&Serum.File.write/1)
      |> Result.aggregate(:init)
    else
      {:error, _} = error -> error
    end
  end

  # Checks if the specified directory already exists.
  # Prints a warning message if so.
  @spec check_dir(binary, boolean) :: Result.t()
  defp check_dir(dir, force?) do
    with true <- File.exists?(dir),
         {:ok, list} <- File.ls(dir) do
      if not Enum.empty?(list) and not force? do
        {:error, {"directory is not empty. use -f (--force) to proceed anyway", dir, 0}}
      else
        :ok
      end
    else
      false -> :ok
      {:error, reason} -> {:error, {reason, dir, 0}}
    end
  end

  # Creates necessary directory structure under the specified directory.
  @spec create_dir(binary) :: Result.t()
  defp create_dir(dir) do
    dirs = [
      "posts",
      "pages",
      "media",
      "templates",
      "includes",
      "assets/css",
      "assets/js",
      "assets/images"
    ]

    mkdir_result =
      dirs
      |> Enum.map(fn x ->
        dirname = Path.join(dir, x)
        {dirname, File.mkdir_p(dirname)}
      end)

    case Enum.reject(mkdir_result, fn {_, x} -> x == :ok end) do
      [] ->
        Enum.each(mkdir_result, fn {dirname, _} -> msg_mkdir(dirname) end)

      [{dirname, {:error, reason}} | _] ->
        {:error, {reason, dirname, 0}}
    end
  end

  # Generates default project metadata files.
  @spec create_info(binary) :: Serum.File.t()
  defp create_info(dir) do
    proj = %{
      site_name: "New Website",
      site_description: "Welcome to my website!",
      author: "Somebody",
      author_email: "somebody@example.com",
      base_url: "/",
      date_format: "{WDfull}, {D} {Mshort} {YYYY}"
    }

    %Serum.File{
      dest: Path.join(dir, "serum.json"),
      out_data: Poison.encode!(proj, pretty: true, indent: 2)
    }
  end

  # Generates a minimal index page for the new project.
  @spec create_index(binary) :: Serum.File.t()
  defp create_index(dir) do
    data = """
    ---
    title: Welcome
    ---

    *Hello, world!*
    """

    %Serum.File{
      dest: Path.join([dir, "pages", "index.md"]),
      out_data: data
    }
  end

  # Generates default template files.
  @spec create_templates(binary) :: [Serum.File.t()]
  defp create_templates(dir) do
    template_files =
      Enum.map(["base", "list", "page", "post"], fn name ->
        %Serum.File{
          dest: Path.join([dir, "templates", "#{name}.html.eex"]),
          out_data: Payload.template(name)
        }
      end)

    include_files =
      Enum.map(["nav"], fn name ->
        %Serum.File{
          dest: Path.join([dir, "includes", "#{name}.html.eex"]),
          out_data: Payload.include(name)
        }
      end)

    template_files ++ include_files
  end

  # Generates the initial `.gitignore` file.
  @spec create_gitignore(binary) :: Serum.File.t()
  defp create_gitignore(dir) do
    %Serum.File{
      dest: Path.join(dir, ".gitignore"),
      out_data: "site\n"
    }
  end
end
