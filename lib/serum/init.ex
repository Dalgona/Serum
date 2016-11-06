defmodule Serum.Init do
  @moduledoc """
  This module contains functions required to initialize a new Serum project.
  """

  import Serum.Payload

  defmacro write(fname, do: str) do
    quote do
      File.open!(unquote(fname), [:write, :utf8], fn f ->
        IO.write(f, unquote(str))
      end)
    end
  end

  @doc """
  Initializes a new Serum project into the given directory `dir`.

  This function will create a minimal required directory structure, and
  generate metadata files and templates.

  **NOTE:** If the directory `dir` is not empty, some contents in that
  directory may be overwritten *without a question*.
  """
  @spec init(dir :: String.t) :: any
  def init(dir) do
    dir = if String.ends_with?(dir, "/"), do: dir, else: dir <> "/"

    dir |> check_dir
        |> init(:dir)
        |> init(:infofile)
        |> init(:page)
        |> init(:templates)
        |> init(:gitignore)
        |> finish
  end

  defp check_dir(dir) do
    if File.exists? dir do
      IO.puts "\x1b[93mWarning: The directory `#{dir}` " <>
              "already exists and might not be empty.\x1b[0m"
    end
    dir
  end

  defp finish(dir) do
    IO.puts "\n\x1b[1mSuccessfully initialized a new Serum project!"
    IO.puts "try `serum build #{dir}` to build the site.\x1b[0m\n"
  end

  defp init(dir, :dir) do
    ["posts", "pages", "media", "templates",
     "assets/css", "assets/js", "assets/images"]
    |> Enum.each(fn x ->
      File.mkdir_p!("#{dir}#{x}")
      IO.puts "Created directory `#{dir}#{x}`."
    end)
    dir
  end

  defp init(dir, :infofile) do
    projinfo =
      %{site_name: "New Website",
        site_description: "Welcome to my website!",
        author: "Somebody",
        author_email: "somebody@example.com",
        base_url: "/",
        date_format: "{WDfull}, {D} {Mshort} {YYYY}",
        preview_length: 200}
      |> Poison.encode!(pretty: true, indent: 2)
    File.open!("#{dir}serum.json", [:write, :utf8], fn f ->
      IO.write(f, projinfo)
    end)
    IO.puts "Generated `#{dir}serum.json`."
    dir
  end

  defp init(dir, :page) do
    write "#{dir}pages/index.md", do: "*Hello, world!*\n"
    dir
  end

  defp init(dir, :templates) do
    %{base: template_base,
      nav:  template_nav,
      list: template_list,
      page: template_page,
      post: template_post}
    |> Enum.each(fn {k, v} ->
      write "#{dir}templates/#{k}.html.eex", do: v
    end)
    IO.puts "Generated essential templates into `#{dir}templates/`."
    dir
  end

  defp init(dir, :gitignore) do
    write "#{dir}.gitignore", do: "site\n"
    IO.puts "Generated `#{dir}.gitignore`."
    dir
  end
end
