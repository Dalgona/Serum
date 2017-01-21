defmodule Serum.Mixfile do
  use Mix.Project

  def project do
    [app: :serum,
     version: "0.9.0+201701212002",
     elixir: "~> 1.4",
     escript: [main_module: Serum.Cmdline],
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    [applications: [:logger, :eex, :cowboy],
     mod: {Serum, []}]
  end

  defp deps do
    [{:earmark, "~> 1.0.1"},
     {:poison, "~> 2.2"},
     {:fs, github: "Dalgona/fs"},
     {:microscope, "~> 1.0"},
     {:timex, "~> 3.0"},
     {:tzdata, "~> 0.1.8", override: true},
     {:floki, "~> 0.12"},
     {:ex_json_schema, "~> 0.5.2"},
     {:credo, "~> 0.5", only: [:dev, :test]},
     {:dialyxir, "~> 0.4", only: [:dev, :test]}]
  end
end
