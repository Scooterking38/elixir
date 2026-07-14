defmodule MyApp do
  use Application

  def start(_type, _args) do

    uri =
      URI.parse(
        System.get_env("DATABASE_URL")
      )


    [username, password] =
      uri.userinfo
      |> URI.decode()
      |> String.split(":", parts: 2)


    database =
      uri.path
      |> String.trim_leading("/")


    children = [
      {
        Postgrex,
        [
          name: MyApp.DB,
          hostname: uri.host,
          username: username,
          password: password,
          database: database,
          ssl: true,
          pool_size: 5
        ]
      },

      {
        Plug.Cowboy,
        [
          scheme: :http,
          plug: MyApp.Router,
          options: [
            port: 4000
          ]
        ]
      }
    ]


    Supervisor.start_link(
      children,
      strategy: :one_for_one,
      name: MyApp.Supervisor
    )
  end
end
