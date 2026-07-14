config :my_app, MyApp.Repo,
  url: System.get_env("DATABASE_URL"),
  pool_size: 10
