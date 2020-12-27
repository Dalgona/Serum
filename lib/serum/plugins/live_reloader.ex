defmodule Serum.Plugins.LiveReloader do
  @moduledoc """
  A Serum plugin that injects the live reloader script at the end of HTML files.

  Once the page is loaded inside your web browser, the injected script tries to
  connect to the Serum development server via WebSocket. When the page receives
  "reload" message from the server, it refreshes the current page.

  If you disable this plugin, you need to manually refresh the page after you
  made some changes to your source files.

  ## Using the Plugin

  You usually don't want the script injected into pages when the Serum
  development server is not running. Let the plugin run only when `Mix.env()`
  is `dev`, and run `MIX_ENV=prod mix serum.build` when you are about to
  publish your website.

      # serum.exs:
      %{
        plugins: [
          {#{__MODULE__ |> to_string() |> String.replace_prefix("Elixir.", "")}, only: :dev}
        ]
      }
  """

  use Serum.V2.Plugin
  alias Serum.V2

  def name, do: "Inject Live Reloader Script"

  def description do
    "Injects the live reloader script at the end of " <>
      "all HTML files for use in the Serum development server."
  end

  def implements, do: [rendered_pages: 2]

  def rendered_pages(files, state) do
    injected_files =
      files
      |> Enum.map(fn %V2.File{out_data: data} = file ->
        %V2.File{file | out_data: data <> _script_snippet()}
      end)

    Result.return({injected_files, state})
  end

  script_snippet =
    :serum
    |> :code.priv_dir()
    |> IO.iodata_to_binary()
    |> Path.join("build_resources/live_reloader.html")
    |> File.read!()

  @doc false
  def _script_snippet, do: unquote(script_snippet)
end
