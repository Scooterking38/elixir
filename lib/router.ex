defmodule MyApp.Router do
  use Plug.Router

  plug :match
  
  # Parsers must handle both urlencoded forms and json if necessary
  plug Plug.Parsers,
    parsers: [:urlencoded],
    pass: ["*/*"]

  plug :fetch_cookies
  plug :dispatch

  # 1. The Home Page (Using proper POST actions)
  get "/:url" do
    send_resp(conn, 200, "you visited #{url}")
  end
end
