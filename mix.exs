defmodule Serum.Mixfile do
  use Mix.Project

  def project do
    [app: :serum,
     version: "0.9.0",
     elixir: "~> 1.2",
     escript: [main_module: Serum.Cmdline],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [applications: [:logger, :eex, :cowboy]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:mydep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:mydep, git: "https://github.com/elixir-lang/mydep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [{:earmark, "~> 1.0.1"},
     {:poison, "~> 2.2"},
     {:cowboy, "~> 1.0.4"},
     {:mime, "~> 1.0.1"},
     {:timex, "~> 3.0"},
     {:tzdata, "~> 0.1.8", override: true},
     {:floki, "~> 0.10.1"},
     {:credo, "~> 0.4.9", only: [:dev, :test]}]
  end
end
