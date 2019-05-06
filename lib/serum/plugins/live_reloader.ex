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

  @behaviour Serum.Plugin

  serum_ver = Version.parse!(Mix.Project.config()[:version])
  serum_req = "~> #{serum_ver.major}.#{serum_ver.minor}"

  def name, do: "Inject Live Reloader Script"
  def version, do: "1.0.0"
  def elixir, do: ">= 1.6.0"
  def serum, do: unquote(serum_req)

  def description do
    "Injects the live reloader script at the end of " <>
      "all HTML files for use in the Serum development server."
  end

  def implements,
    do: [
      :rendered_page
    ]

  script_snippet =
    :serum
    |> :code.priv_dir()
    |> IO.iodata_to_binary()
    |> Path.join("build_resources/live_reloader.html")
    |> File.read!()

  def rendered_page(%{out_data: data} = file) do
    {:ok, %{file | out_data: data <> unquote(script_snippet)}}
  end
end
