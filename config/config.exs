use Mix.Config

config :serum, service: Serum.DevServer.Service.GenServer

if Mix.env() === :dev do
  config :mix_test_watch,
    tasks: [
      "coveralls.html",
      "format --check-formatted",
      "credo --all --strict"
    ]
end

if Mix.env() === :test do
  import_config("test.exs")
end
