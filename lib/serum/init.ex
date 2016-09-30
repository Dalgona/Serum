defmodule Serum.Init do
  @moduledoc """
  This module contains functions which are required to initialize a new Serum
  project. These functions should be called by `Serum.init/1`.
  """

  import Serum.Payload

  def init(dir) do
    dir = if String.ends_with?(dir, "/"), do: dir, else: dir <> "/"
    if File.exists? dir do
      IO.puts "\x1b[93mWarning: The directory `#{dir}` " <>
              "already exists and might not be empty.\x1b[0m"
    end

    init :dir, dir
    init :infofile, dir
    init :page, dir
    init :templates, dir

    File.open! "#{dir}.gitignore", [:write, :utf8], fn f ->
      IO.write f, "site\n"
    end
    IO.puts "Generated `#{dir}.gitignore`."

    IO.puts "\n\x1b[1mSuccessfully initialized a new Serum project!"
    IO.puts "try `serum build #{dir}` to build the site.\x1b[0m\n"
  end

  defp init(:dir, dir) do
    ["posts", "pages", "media", "templates",
     "assets/css", "assets/js", "assets/images"]
    |> Enum.each(fn x ->
      File.mkdir_p! "#{dir}#{x}"
      IO.puts "Created directory `#{dir}#{x}`."
    end)
  end

  defp init(:infofile, dir) do
    projinfo =
      %{site_name: "New Website",
        site_description: "Welcome to my website!",
        author: "Somebody",
        author_email: "somebody@example.com",
        base_url: "/",
        date_format: "{WDFull}, {D} {Mshort} {YYYY}"}
      |> Poison.encode!(pretty: true, indent: 2)
    File.open! "#{dir}serum.json", [:write, :utf8], fn f ->
      IO.write f, projinfo
    end
    IO.puts "Generated `#{dir}serum.json`."
  end

  defp init(:page, dir) do
    File.open! "#{dir}pages/index.md", [:write, :utf8], fn f ->
      IO.write f, "*Hello, world!*\n"
    end
    File.open! "#{dir}pages/pages.json", [:write, :utf8], fn f ->
      tmp = Poison.encode! [
        %Serum.Pageinfo{
          name: "index",
          type: "md",
          title: "Welcome!",
          menu: true,
          menu_text: "Home",
          menu_icon: ""}
      ], pretty: true, indent: 2
      IO.write f, tmp
    end
    IO.puts "Generated `#{dir}pages/pages.json`."
  end

  defp init(:templates, dir) do
    %{base: template_base,
      nav:  template_nav,
      list: template_list,
      page: template_page,
      post: template_post}
    |> Enum.each(fn {k, v} ->
      File.open! "#{dir}templates/#{k}.html.eex", [:write, :utf8], fn f ->
        IO.write f, v
      end
    end)
    IO.puts "Generated essential templates into `#{dir}templates/`."
  end
end
