# Configuration for the testing environment
import Config

config :serum, service: Serum.DevServer.Service.Mock
config :serum, command_handler: Serum.DevServer.CommandHandler.Mock
