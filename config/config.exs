# General application configuration
import Config

config :event_manager,
  ecto_repos: [EventManager.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :event_manager, EventManagerWeb.Endpoint,
  url: [host: "localhost"],
  render_errors: [
    formats: [html: EventManagerWeb.ErrorHTML, json: EventManagerWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: EventManager.PubSub,
  live_view: [signing_salt: "YourSecretKeyHere123"]

# Configures the mailer
config :event_manager, EventManager.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Configure Phoenix connections
config :phoenix, :json_library, Jason

