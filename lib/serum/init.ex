defmodule Serum.Init do
  @moduledoc """
  This module contains functions required to initialize a new Serum project.
  """

  import Serum.Payload
  import Serum.Util

  @type dirname   :: binary
  @type ok_result :: {:ok, dirname}

  @doc """
  Initializes a new Serum project into the given directory `dir`.

  This function will create a minimal required directory structure, and
  generate metadata files and templates.

  **NOTE:** If the directory `dir` is not empty, some contents in that
  directory may be overwritten *without a question*.
  """
  @spec init(dirname) :: :ok
  def init(dir) do
    dir = if String.ends_with?(dir, "/"), do: dir, else: dir <> "/"

    :ok =
      dir
      |> check_dir
      |> init_dir
      |> init_info
      |> init_index
      |> init_templates
      |> init_gitignore
      |> finish
  end

  # Checks if the specified directory already exists.
  # Prints a warning message if so.
  @spec check_dir(dirname) :: ok_result
  defp check_dir(dir) do
    if File.exists? dir do
      warn "The directory `#{dir}` already exists and might not be empty."
    end
    {:ok, dir}
  end

  # Prints an information message after successfully initializing a new project.
  @spec finish(ok_result) :: :ok
  defp finish({:ok, dir}) do
    IO.puts "\n\x1b[1mSuccessfully initialized a new Serum project!"
    IO.puts "try `serum build #{dir}` to build the site.\x1b[0m\n"
  end

  # Creates necessary directory structure under the specified directory.
  @spec init_dir(ok_result) :: ok_result
  defp init_dir({:ok, dir}) do
    ["posts", "pages", "media", "templates", "includes",
     "assets/css", "assets/js", "assets/images"]
    |> Enum.each(fn x ->
      File.mkdir_p! "#{dir}#{x}"
      IO.puts "Created directory `#{dir}#{x}`."
    end)
    {:ok, dir}
  end

  # Generates default project metadata files.
  @spec init_info(ok_result) :: ok_result
  defp init_info({:ok, dir}) do
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
    {:ok, dir}
  end

  # Generates a minimal index page for the new project.
  @spec init_index(ok_result) :: ok_result
  defp init_index({:ok, dir}) do
    fwrite "#{dir}pages/index.md", "# Welcome\n\n*Hello, world!*\n"
    IO.puts "Generated `#{dir}pages/pages.json`."
    {:ok, dir}
  end

  # Generates default template files.
  @spec init_templates(ok_result) :: ok_result
  defp init_templates({:ok, dir}) do
    [:base, :list, :page, :post]
    |> Enum.each(fn k ->
      fwrite "#{dir}templates/#{k}.html.eex", template(k)
    end)
    IO.puts "Generated essential templates into `#{dir}templates/`."

    [:nav]
    |> Enum.each(fn k ->
      fwrite "#{dir}includes/#{k}.html.eex", include(k)
    end)
    IO.puts "Generated includes into `#{dir}includes/`."
    {:ok, dir}
  end

  # Generates the initial `.gitignore` file.
  @spec init_gitignore(ok_result) :: ok_result
  defp init_gitignore({:ok, dir}) do
    fwrite "#{dir}.gitignore", "site\n"
    IO.puts "Generated `#{dir}.gitignore`."
    {:ok, dir}
  end
end
