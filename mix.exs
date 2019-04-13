defmodule Serum.Mixfile do
  use Mix.Project

  @serum_version "0.10.0"

  def project do
    [
      app: :serum,
      version: @serum_version,
      elixir: "~> 1.6",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: preferred_cli_env(),
      deps: deps(),
      package: package()
    ]
  end

  def application do
    [applications: [:logger, :eex, :cowboy, :tzdata], mod: {Serum, []}]
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
      {:file_system, "~> 0.2.6"},
      {:microscope, "~> 1.1.1"},
      {:timex, "~> 3.2"},
      {:ex_json_schema, "~> 0.5"},
      {:credo, "~> 1.0", only: [:dev, :test]},
      {:excoveralls, "~> 0.10", only: [:test]},
      {:dialyxir, "~> 0.5", only: [:dev, :test]},
      {:floki, "~> 0.20"}
    ]
  end

  defp package do
    [
      name: "serum",
      description: "Yet another static website generator written in Elixir",
      maintainers: ["Eunbin Jeong"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/Dalgona/Serum",
        "Website" => "http://dalgona.github.io/Serum"
      }
    ]
  end
end
