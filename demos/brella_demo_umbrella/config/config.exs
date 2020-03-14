# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of Mix.Config.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
use Mix.Config



config :brella_demo_web,
  generators: [context_app: :brella_demo]

# Configures the endpoint
config :brella_demo_web, BrellaDemoWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "Fv0RSNi8fFMWxDxhyWT0Kvbfik9nVAXVplSyge/GbnhnrBLVqpzrx1u5ACaJqhnP",
  render_errors: [view: BrellaDemoWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: BrellaDemoWeb.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [signing_salt: "vJnhEUzc"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
