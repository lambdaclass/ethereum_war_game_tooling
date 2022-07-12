import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :frontend, Frontend.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "frontend_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :frontend, FrontendWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "X/Oa9qCWLmSok+X+93QSqgJbe1QeD1mZ9s8miQvyv4R495GyaQK8y9sKcMoTuxl8",
  server: false

# In test we don't send emails.
config :frontend, Frontend.Mailer, adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
