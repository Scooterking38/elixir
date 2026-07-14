defmodule MyApp.Application do
  use Application

  def start(_, _) do
    children = [
      MyApp.Repo,
      {Plug.Cowboy, scheme: :http, plug: MyApp.Router, options: [port: 4000]}
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end

defmodule MyApp.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "hello")
  end

  match _ do
    send_resp(conn, 404, "poopoo you loser")
  end
end
