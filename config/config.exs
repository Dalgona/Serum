use Mix.Config

config :serum, service: Serum.DevServer.Service.GenServer

if Mix.env() === :test do
  import_config("test.exs")
end
