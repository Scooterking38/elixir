defmodule MyApp.Router do
  use Plug.Router

  plug :match

  # Parsers are required so your application can read form data and query strings
  plug Plug.Parsers,
    parsers: [:urlencoded],
    pass: ["*/*"]

  plug :dispatch
  plug :fetch_cookies

  # 1. The Home Page (Zero JavaScript Form)
  get "/" do
    send_resp(conn, 200, """
    <!DOCTYPE html>
    <html>
    <body>
        <h1>MyApp Auth</h1>
        
        <h3>Log In (Queries /profile directly)</h3>
        <form action="/profile" method="GET">
            <label>Username:</label>
            <input type="text" name="username" required>
            <button type="submit">View Profile</button>
        </form>

        <hr>

        <h3>Manual API Reference:</h3>
        <ul>
            <li>Signup: <code>/signup/name/password</code></li>
            <li>Login: <code>/login/name/password</code></li>
            <li>Profile: <code>/profile</code></li>
        </ul>
    </body>
    </html>
    """)
  end

  # 2. User Registration Endpoint (Guarded against DB crashes)
  get "/signup/:username/:password" do
    result =
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

        "Created user #{username}"
      rescue
        error -> "Signup Database Error: #{inspect(error)}"
      end

    send_resp(conn, 200, result)
  end

  # 3. User Login (Guarded against DB crashes)
  get "/login/:username/:password" do
    try do
      result =
        Postgrex.query!(
          MyApp.DB,
          """
          SELECT id, password_hash
          FROM users
          WHERE username=$1
          """,
          [username]
        )

      case result.rows do
        [[user_id, hash]] ->
          if Argon2.verify_pass(password, hash) do
            token =
              :crypto.strong_rand_bytes(32)
              |> Base.url_encode64()

            Postgrex.query!(
              MyApp.DB,
              """
              INSERT INTO sessions(user_id, token)
              VALUES($1,$2)
              """,
              [user_id, token]
            )

            conn
            |> put_resp_cookie("session", token, http_only: true)
            |> send_resp(200, "Logged in as #{username}")
          else
            send_resp(conn, 401, "Wrong password")
          end

        [] ->
          send_resp(conn, 404, "User not found")
      end
    rescue
      error -> send_resp(conn, 500, "Login Database Error: #{inspect(error)}")
    end
  end

  # 4. Authenticated Profile Page (Guarded against Empty Cookies, Params, and DB crashes)
  get "/profile" do
    # Safely fetch query parameters so conn.params is populated
    conn = fetch_query_params(conn)
    username_param = Map.get(conn.params, "username")

    # Safely read the session cookie using Map.get with a default fallback of nil
    token = Map.get(conn.cookies, "session", nil)

    if is_nil(token) or token == "" do
      # Instead of crashing, respond cleanly with an unauthorized message
      conn
      |> put_resp_content_type("text/plain")
      |> send_resp(401, "Not logged in (No session cookie found)")
    else
      try do
        result =
          Postgrex.query!(
            MyApp.DB,
            """
            SELECT users.username, users.created_at
            FROM users
            JOIN sessions
            ON users.id = sessions.user_id
            WHERE sessions.token = $1
            """,
            [token]
          )

        case result.rows do
          [[name, created]] ->
            # Check if the query parameter matches the logged-in session user
            if is_nil(username_param) or username_param == name do
              send_resp(
                conn,
                200,
                """
                Profile

                Username: #{name}
                Created: #{created}
                """
              )
            else
              # Access forbidden - show image
              send_resp(
                conn,
                403,
                ~s(<img src="https://wcti12.com/resources/media/61beaa02-ddd0-4d19-a040-edf2da650e47-large16x9_massage.jpg">)
              )
            end

          [] ->
            send_resp(conn, 401, "Invalid session token")
        end
      rescue
        # If the SQL query fails (e.g. missing tables/invalid schemas), print the actual error
        error ->
          send_resp(conn, 500, "Profile Database Error: #{inspect(error)}")
      end
    end
  end

  # Catch-all Route
  match _ do
    send_resp(conn, 404, "Not Found")
  end
end
