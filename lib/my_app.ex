# 1. The Supervisor (Boots the server on port 4000)
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Plug.Cowboy, scheme: :http, plug: MyApp.Router, options: [port: 4000]}
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

# 2. The Web Router & HTML Interface
defmodule MyApp.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  # Serve the web interface
  get "/profile/:username" do
    html_content = """
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Elixir Live Portal</title>
        <style>
            body {
                font-family: system-ui, sans-serif;
                background-color: #f4f4f9;
                color: #333;
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                height: 100vh;
                margin: 0;
            }
            .card {
                background: white;
                padding: 2rem;
                border-radius: 12px;
                box-shadow: 0 4px 15px rgba(0,0,0,0.05);
                text-align: center;
            }
            h1 { color: #6236FF; }
        </style>
    </head>
    <body>
        <div class="card">
            <h1>💜 Hello from Elixir! Apparently your name is #{username}</h1>
            <p>This page is being served directly from a GitHub Actions runner.</p>
        </div>
    </body>
    </html>
    """
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html)
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
