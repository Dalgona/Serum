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

  def application do
    [applications: [:logger, :eex, :cowboy, :fs],
     mod: {Serum, []}]
  end

  defp deps do
    [{:earmark, "~> 1.0.1"},
     {:poison, "~> 2.2"},
     {:fs, github: "Dalgona/fs"},
     {:microscope, "~> 0.4.2"},
     {:timex, "~> 3.0"},
     {:tzdata, "~> 0.1.8", override: true},
     {:floki, "~> 0.10.1"},
     {:ex_json_schema, "~> 0.5.2"},
     {:credo, "~> 0.5", only: [:dev, :test]},
     {:dialyxir, "~> 0.4.0", only: [:dev, :test]}]
  end
end
