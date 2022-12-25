import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :doom_supervisor, DoomSupervisorWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "VRPVIbMFwU2E1/Xd22YXglrElnc8IZ1wEQPgQz8whoFpZhbLExOoRVjRBcH1nwgB",
  server: false

# In test we don't send emails.
config :doom_supervisor, DoomSupervisor.Mailer,
  adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
