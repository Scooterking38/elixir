defmodule MyApp.Router do
  use Plug.Router

  import Plug.Conn

  plug :match

  plug Plug.Parsers,
    parsers: [:urlencoded],
    pass: ["*/*"],
    json_decoder: Jason

  plug :fetch_cookies
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Welcome! You are at the home route.")
  end

  get "/:code" do
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(
      200,
      ~s(<img src="https://http.dog/#{code}.jpg" alt="HTTP #{code}" /><img src="https://http.cat/#{code}.jpg" alt="HTTP #{code}" /><img src="https://http.fish/#{code}.jpg" alt="HTTP #{code}" /><img src="https://http.pizza/#{code}.jpg" alt="HTTP #{code}" />)
    )
  end

  # Catch-all for any unmatched routes
  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
