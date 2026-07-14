defmodule MyApp do
  use Application

  def start(_type, _args) do
    children = [
      {Postgrex,
       [
         name: MyApp.DB,
         url: System.get_env("DATABASE_URL"),
         pool_size: 5
       ]},
      {Plug.Cowboy,
       scheme: :http,
       plug: MyApp.Router,
       options: [port: 4000]}
    ]

    Supervisor.start_link(
      children,
      strategy: :one_for_one
    )
  end
end
