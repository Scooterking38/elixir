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
    # Serve the web interface with interactive input
    get "/" do
      html_content = """
      <!DOCTYPE html>
      <html lang="en">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Elixir Router Redirector</title>
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
                  padding: 2.5rem;
                  border-radius: 12px;
                  box-shadow: 0 4px 15px rgba(0,0,0,0.05);
                  text-align: center;
                  max-width: 400px;
                  width: 100%;
              }
              h1 { color: #6236FF; margin-bottom: 1.5rem; }
              
              /* Input & Button Styling */
              input {
                  width: 80%;
                  padding: 10px;
                  font-size: 1rem;
                  border: 2px solid #ddd;
                  border-radius: 6px;
                  margin-bottom: 1.5rem;
                  outline: none;
                  transition: border-color 0.2s;
              }
              input:focus {
                  border-color: #6236FF;
              }
              .btn {
                  display: inline-block;
                  background-color: #6236FF;
                  color: white;
                  text-decoration: none;
                  padding: 10px 20px;
                  font-weight: bold;
                  border-radius: 6px;
                  transition: background-color 0.2s;
              }
              .btn:hover {
                  background-color: #4922D3;
              }
          </style>
      </head>
      <body>
          <div class="card">
              <h1>Type Your Name</h1>
              
              <input type="text" id="name-input" placeholder="Enter name:">
              
              <br>
              
              <a href="./profile/guest" id="profile-link" class="btn">Go to Profile</a>
          </div>
  
          <script>
              const nameInput = document.getElementById('name-input');
              const profileLink = document.getElementById('profile-link');
  
              // Listen for whenever the user types in the input box
              nameInput.addEventListener('input', (event) => {
                  const username = event.target.value.trim();
                  
                  if (username === '') {
                      // Fallback if they clear the text box
                      profileLink.setAttribute('href', './profile/guest');
                  } else {
                      // Update the link's href dynamically!
                      profileLink.setAttribute('href', `./profile/${encodeURIComponent(username)}`);
                  }
              });
          </script>
      </body>
      </html>
      """
  
      conn
      |> put_resp_content_type("text/html")
      |> send_resp(200, html_content)
    end
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
            <title>🤪🤪🤪Hey bruh, I know you are called #{username}.🤕🤕🤕</title>
        </div>
    </body>
    </html>
    """
    conn
    |> put_resp_content_type("text/html")
    |> send_resp(200, html_content)
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
