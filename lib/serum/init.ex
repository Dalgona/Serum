defmodule Serum.Init do
  @moduledoc """
  This module contains functions required to initialize a new Serum project.
  """

  require Serum.Util
  import Serum.Payload
  import Serum.Util
  alias Serum.Error

  @doc """
  Initializes a new Serum project into the given directory `dir`.

  This function will create a minimal required directory structure, and
  generate metadata files and templates.
  """
  @spec init(binary, boolean) :: Error.result

  def init(dir, force?) do
    with :ok <- check_dir(dir, force?),
         :ok <- create_dir(dir)
    do
      create_info dir
      create_index dir
      create_templates dir
      create_gitignore dir
      :ok
    else
      {:error, _} = error -> error
    end
  end

  # Checks if the specified directory already exists.
  # Prints a warning message if so.
  @spec check_dir(binary, boolean) :: Error.result

  defp check_dir(dir, force?) do
    with true <- File.exists?(dir),
         {:ok, list} <- File.ls(dir)
    do
      if not Enum.empty?(list) and not force? do
        {:error,
         {"directory is not empty. use -f (--force) to proceed anyway", dir, 0}}
      else
        :ok
      end
    else
      false -> :ok
      {:error, reason} -> {:error, {reason, dir, 0}}
    end
  end

  # Creates necessary directory structure under the specified directory.
  @spec create_dir(binary) :: Error.result

  defp create_dir(dir) do
    dirs =
      ["posts", "pages", "media", "templates", "includes",
       "assets/css", "assets/js", "assets/images"]
    mkdir_result =
      dirs
      |> Enum.map(fn x ->
        dirname = Path.join dir, x
        {dirname, File.mkdir_p(dirname)}
      end)
    case Enum.reject(mkdir_result, fn {_, x} -> x == :ok end) do
      [] ->
        Enum.each mkdir_result, fn {dirname, _} -> msg_mkdir dirname end
      [{dirname, {:error, reason}}|_] ->
        {:error, {reason, dirname, 0}}
    end
  end

  # Generates default project metadata files.
  @spec create_info(binary) :: :ok

  defp create_info(dir) do
    projinfo =
      %{site_name: "New Website",
        site_description: "Welcome to my website!",
        author: "Somebody",
        author_email: "somebody@example.com",
        base_url: "/",
        date_format: "{WDfull}, {D} {Mshort} {YYYY}",
        preview_length: 200}
      |> Poison.encode!(pretty: true, indent: 2)
    fname = Path.join dir, "serum.json"
    fwrite fname, projinfo
    msg_gen fname
  end

  # Generates a minimal index page for the new project.
  @spec create_index(binary) :: :ok

  defp create_index(dir) do
    fname = Path.join dir, "pages/index.md"
    fwrite fname, """
    ---
    title: Welcome
    ---

    *Hello, world!*
    """
    msg_gen fname
  end

  # Generates default template files.
  @spec create_templates(binary) :: :ok

  defp create_templates(dir) do
    [:base, :list, :page, :post]
    |> Enum.each(fn k ->
      fname = Path.join([dir, "templates", "#{k}.html.eex"])
      fwrite fname, template(k)
      msg_gen fname
    end)

    [:nav]
    |> Enum.each(fn k ->
      fname = Path.join([dir, "includes", "#{k}.html.eex"])
      fwrite fname, include(k)
      msg_gen fname
    end)
  end

  # Generates the initial `.gitignore` file.
  @spec create_gitignore(binary) :: :ok

  defp create_gitignore(dir) do
    fname = Path.join dir, ".gitignore"
    fwrite fname, "site\n"
    msg_gen fname
  end
end
