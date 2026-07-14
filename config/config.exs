import Config

config :my_app,
  database_url: System.get_env("DATABASE_URL")
