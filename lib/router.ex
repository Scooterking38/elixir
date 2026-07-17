defmodule MyApp.Router do
  use Plug.Router

  plug :match
  
  # Parsers must handle both urlencoded forms and json if necessary
  plug Plug.Parsers,
    parsers: [:urlencoded, :json],
    pass: ["*/*"],
    json_decoder: Jason

  plug :fetch_cookies
  plug :dispatch

  # 1. The Home Page (Using proper POST actions)
  get "/" do
    send_resp(conn, 200, """
    <!DOCTYPE html>
    <html>
    <body>
        <h1>Authentication</h1>
        
        <h3>SIGNUP</h3>
        <form action="/signup" method="POST">
            <label>Username:</label>
            <input type="text" name="username" required>
            <label>Password:</label>
            <input type="password" name="password" required>
            <button type="submit">Signup</button>
        </form>

        <h3>LOGIN</h3>
        <form action="/login" method="POST">
            <label>Username:</label>
            <input type="text" name="username" required>
            <label>Password:</label>
            <input type="password" name="password" required>
            <button type="submit">Login</button>
        </form>

        <h3>PROFILE</h3>
        <form action="/profile" method="GET">
            <button type="submit">View My Profile</button>
        </form>
    </body>
    </html>
    """)
  end

  # 2. User Registration (Changed to POST and reading from body params)
  post "/signup" do
    %{"username" => username, "password" => password} = conn.body_params

    try do
      hash = Argon2.hash_pwd_salt(password)

      Postgrex.query!(
        MyApp.DB,
        """
        INSERT INTO users(username, password_hash)
        VALUES($1, $2)
        ON CONFLICT (username) DO NOTHING
        """,
        [username, hash]
      )

      send_resp(conn, 201, "Created user #{username}")
    rescue
      error -> send_resp(conn, 500, "Signup Database Error: #{inspect(error)}")
    end
  end

  # 3. User Login (Changed to POST and reading from body params)
  post "/login" do
    %{"username" => username, "password" => password} = conn.body_params

    try do
      result = Postgrex.query!(
        MyApp.DB,
        "SELECT id, password_hash FROM users WHERE username = $1",
        [username]
      )

      case result.rows do
        [[user_id, hash]] ->
          if Argon2.verify_pass(password, hash) do
            # Generate session token safely
            token = :crypto.strong_rand_bytes(32) |> Base.url_encode64()

            Postgrex.query!(
              MyApp.DB,
              "INSERT INTO sessions(user_id, token) VALUES($1, $2)",
              [user_id, token]
            )

            conn
            |> put_resp_cookie("session", token, http_only: true, secure: true, same_site: "Lax")
            |> send_resp(200, "Logged in as #{username}")
          else
            send_resp(conn, 401, "Invalid credentials")
          end

        [] ->
          # To prevent timing attacks, simulate password verification even if user doesn't exist
          Argon2.no_user_verify()
          send_resp(conn, 401, "Invalid credentials")
      end
    rescue
      error -> send_resp(conn, 500, "Login Database Error: #{inspect(error)}")
    end
  end

  # 4. Authenticated Profile Page
  get "/profile" do
    token = Map.get(conn.cookies, "session")

    if is_nil(token) || token == "" do
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(401, "Not logged in")
    else
      try do
        result = Postgrex.query!(
          MyApp.DB,
          """
          SELECT users.username, users.created_at
          FROM users
          JOIN sessions ON users.id = sessions.user_id
          WHERE sessions.token = $1
          """,
          [token]
        )

        case result.rows do
          [[name, created]] ->
            send_resp(conn, 200, "Profile\n\nUsername: #{name}\nCreated: #{created}")
          [] ->
            send_resp(conn, 401, "Invalid session token")
        end
      rescue
        error -> send_resp(conn, 500, "Profile Database Error: #{inspect(error)}")
      end
    end
  end

  # Catch-all Route
  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
