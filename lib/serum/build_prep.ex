defmodule Serum.BuildPrep do
  @moduledoc """
  This module contains functions which are used to prepare the site building
  process.
  """

  alias Serum.Error
  alias Serum.BuildDataStorage

  @spec check_tz() :: Error.result
  def check_tz do
    try do
      Timex.local
      :ok
    rescue
      _ -> {:error, :system_error, "system timezone is not set"}
    end
  end

  @spec load_templates(String.t) :: Error.result
  def load_templates(dir) do
    IO.puts "Loading templates..."
    ["base", "list", "page", "post", "nav"]
    |> Enum.map(&do_load_templates(dir, &1))
    |> Error.filter_results(:load_templates)
  end

  @spec do_load_templates(String.t, String.t) :: Error.result
  defp do_load_templates(dir, name) do
    path = "#{dir}templates/#{name}.html.eex"
    case File.read path do
      {:ok, data} ->
        try do
          template_str = "<% import Serum.TemplateHelper %>" <> data
          ast = EEx.compile_string template_str
          BuildDataStorage.put self(), "template", name, ast
          :ok
        rescue
          e in EEx.SyntaxError ->
            {:error, :invalid_template, {e.message, path, e.line}}
          e in SyntaxError ->
            {:error, :invalid_template, {e.description, path, e.line}}
          e in TokenMissingError ->
            {:error, :invalid_template, {e.description, path, e.line}}
        end
      {:error, reason} ->
        {:error, :file_error, {reason, path, 0}}
    end
  end

  @spec scan_pages(String.t, String.t) :: Error.result
  def scan_pages(src, dest) do
    dir = src <> "pages/"
    IO.puts "Scanning `#{dir}` directory..."
    if File.exists?(dir), do: do_scan_pages(dir, src, dest),
    else: {:error, :file_error, {:enoent, dir, 0}}
  end

  @spec do_scan_pages(String.t, String.t, String.t) :: :ok
  defp do_scan_pages(path, src, dest) do
    path
    |> File.ls!
    |> Enum.each(fn x ->
      f = Regex.replace ~r(/+), "#{path}/#{x}", "/"
      cond do
        File.dir? f ->
          f |> String.replace_prefix("#{src}pages/", dest) |> File.mkdir_p!
          do_scan_pages f, src, dest
        String.ends_with?(f, ".md") or String.ends_with?(f, ".html") ->
          files = BuildDataStorage.get self(), "pages_file"
          BuildDataStorage.put self(), "pages_file", [f|files]
        :otherwise -> :skip
      end
    end)
  end
end
