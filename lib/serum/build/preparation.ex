defmodule Serum.Build.Preparation do
  @moduledoc """
  This module contains functions which are used to prepare the site building
  process.
  """

  alias Serum.Error
  alias Serum.ProjectInfo
  alias Serum.Validation

  @spec check_tz() :: Error.result
  def check_tz do
    try do
      Timex.local
      :ok
    rescue
      _ -> {:error, :system_error, "system timezone is not set"}
    end
  end

  @spec load_info(String.t) :: Error.result
  def load_info(dir) do
    path = dir <> "serum.json"
    IO.puts "Reading project metadata `#{path}`..."
    case File.read path do
      {:ok, data} ->
        do_load_info path, data
      {:error, reason} ->
        {:error, :file_error, {reason, "#{dir}serum.json", 0}}
    end
  end

  @spec do_load_info(String.t, String.t) :: Error.result
  defp do_load_info(path, data) do
    case Poison.decode data do
      {:ok, proj} ->
        validate proj
      {:error, :invalid, pos} ->
        {:error, :json_error,
         {"parse error at position #{pos}", path, 0}}
      {:error, {:invalid, token, pos}} ->
        {:error, :json_error,
         {"parse error near `#{token}' at position #{pos}", path, 0}}
    end
  end

  @spec validate(map) :: Error.result
  defp validate(proj) do
    Validation.load_schema
    case Validation.validate "serum.json", proj do
      :ok ->
        proj |> ProjectInfo.new() |> ProjectInfo.load()
        :ok
      error -> error
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
          Serum.put_data "template", name, ast
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
          Serum.put_data "pages_file", [f|Serum.get_data "pages_file"]
        :otherwise -> :skip
      end
    end)
  end
end
