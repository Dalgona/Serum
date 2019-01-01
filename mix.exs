defmodule Serum.Mixfile do
  use Mix.Project

  def project do
    [
      app: :serum,
      version: "0.6.0",
      elixir: "~> 1.6",
      escript: [main_module: Serum.CLI],
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env(),
      deps: deps()
    ]
  end

  def application do
    [applications: [:logger, :eex, :cowboy], mod: {Serum, []}]
  end

  defp preferred_cli_env do
    [
      coveralls: :test,
      "coveralls.detail": :test,
      "coveralls.travis": :test,
      "coveralls.html": :test
    ]
  end

  defp deps do
    [
      {:earmark, "~> 1.2"},
      {:poison, "~> 3.1"},
      {:fs, github: "Dalgona/fs"},
      {:microscope, "~> 1.0"},
      {:timex, "~> 3.2"},
      {:tzdata, "~> 0.1.8", override: true},
      {:ex_json_schema, "~> 0.5"},
      {:credo, "~> 0.8", only: [:dev, :test]},
      {:excoveralls, "~> 0.6", only: [:test]},
      {:dialyxir, "~> 0.5", only: [:dev, :test]},
      {:floki, "~> 0.20"}
    ]
  end
end
