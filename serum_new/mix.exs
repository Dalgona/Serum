defmodule Serum.New.MixProject do
  use Mix.Project

  @serum_version "0.9.0"

  def project do
    [
      app: :serum_new,
      version: @serum_version,
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    []
  end

  defp package do
    [
      name: "serum_new",
      description: "Provides \"mix serum.new\", the Serum installer",
      maintainers: ["Eunbin Jeong"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/Dalgona/Serum",
        "Website" => "http://dalgona.github.io/Serum"
      }
    ]
  end
end
