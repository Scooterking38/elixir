defmodule MyApp.Router do
  use Plug.Router

  plug :match
  
  plug Plug.Parsers,
    parsers: [:urlencoded],
    pass: ["*/*"],
    json_decoder: Jason

  plug :fetch_cookies
  plug :dispatch

  # 1. Handle the literal root URL "/"
  get "/" do
    send_resp(conn, 200, "Welcome! You are at the home root.")
  end

  # 2. Handle dynamic single segments (e.g., /hello, /about)
  get "/:url" do
    # FIX: Changed ${url} to Elixir's native # {url} interpolation
    send_resp(conn, 200, "you visited #{url}")
  end

  # 3. Catch-all fallback so missing paths return a 404 instead of crashing
  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
