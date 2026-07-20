defmodule MyApp.Router do
  use Plug.Router

  plug :match
  
  plug Plug.Parsers,
    parsers: [:urlencoded],
    pass: ["*/*"],
    json_decoder: Jason

  plug :fetch_cookies
  plug :dispatch

  get "/" do
    send_resp(conn, 200, "Welcome! You are at the home root.")
  end

  get "/:code" do
    send_resp(conn, 200, "<img href="https://http.dog/#{code}.jpg"></img>")

    
  end

  # 3. Catch-all fallback so missing paths return a 404 instead of crashing
  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
