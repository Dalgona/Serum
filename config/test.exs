# Configuration for the testing environment
use Mix.Config

config :serum, service: Serum.DevServer.Service.Mock
config :serum, command_handler: Serum.DevServer.CommandHandler.Mock
