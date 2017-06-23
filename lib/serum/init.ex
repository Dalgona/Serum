defmodule Serum.Init do
  @moduledoc """
  This module contains functions required to initialize a new Serum project.
  """

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
    dir = if String.ends_with?(dir, "/"), do: dir, else: dir <> "/"

    with :ok <- check_dir(dir, force?),
         :ok <- create_dir(dir)
    do
      create_info dir
      create_index dir
      create_templates dir
      create_gitignore dir
      finish dir
    else
      {:error, _, _} = error ->
        Error.show error
        IO.puts """

        Could not initialize a new project.
        Make sure the target directory is writable.
        """
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
        {:error, :init_error,
         {"directory is not empty. Use -f option to proceed anyway.", dir, 0}}
      else
        :ok
      end
    else
      false -> :ok
      {:error, reason} -> {:error, :file_error, {reason, dir, 0}}
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
        dirname = dir <> x
        {dirname, File.mkdir_p(dirname)}
      end)
    case Enum.reject(mkdir_result, fn {_, x} -> x == :ok end) do
      [] ->
        Enum.each mkdir_result, fn {dirname, _} ->
          IO.puts "Created directory `#{dirname}`."
        end
        :ok
      [{dirname, {:error, reason}}|_] ->
        {:error, :file_error, {reason, dirname, 0}}
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
    fwrite "#{dir}serum.json", projinfo
    IO.puts "Generated `#{dir}serum.json`."
  end

  # Generates a minimal index page for the new project.
  @spec create_index(binary) :: :ok

  defp create_index(dir) do
    fwrite "#{dir}pages/index.md", """
    ---
    title: Welcome
    ---

    *Hello, world!*
    """
    IO.puts "Generated `#{dir}pages/pages.json`."
  end

  # Generates default template files.
  @spec create_templates(binary) :: :ok

  defp create_templates(dir) do
    [:base, :list, :page, :post]
    |> Enum.each(fn k ->
      fwrite "#{dir}templates/#{k}.html.eex", template(k)
    end)
    IO.puts "Generated essential templates into `#{dir}templates/`."

    [:nav]
    |> Enum.each(fn k ->
      fwrite "#{dir}includes/#{k}.html.eex", include(k)
    end)
    IO.puts "Generated includable templates into `#{dir}includes/`."
  end

  # Generates the initial `.gitignore` file.
  @spec create_gitignore(binary) :: :ok

  defp create_gitignore(dir) do
    fwrite "#{dir}.gitignore", "site\n"
    IO.puts "Generated `#{dir}.gitignore`."
  end

  # Prints an information message after successfully initializing a new project.
  @spec finish(binary) :: :ok

  defp finish(dir) do
    IO.puts "\n\x1b[1mSuccessfully initialized a new Serum project!"
    IO.puts "try `serum build #{dir}` to build the site.\x1b[0m\n"
  end
end
