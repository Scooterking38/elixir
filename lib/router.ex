defmodule MyApp.Router do
  use Plug.Router

  plug :match
  plug :dispatch
  plug :fetch_cookies


  get "/" do
    send_resp(conn, 200, """
    MyApp Auth

    Signup:
    /signup/name/password

    Login:
    /login/name/password

    Profile:
    /profile/name
    """)
  end


  get "/signup/:username/:password" do
    result =
      try do
        hash =
          Argon2.hash_pwd_salt(password)

        Postgrex.query!(
          MyApp.DB,
          """
          INSERT INTO users(username, password_hash)
          VALUES($1, $2)
          ON CONFLICT (username) DO NOTHING
          """,
          [
            username,
            hash
          ]
        )

        "Created user #{username}"

      rescue
        error ->
          "Signup error: #{inspect(error)}"
      end

    send_resp(
      conn,
      200,
      result
    )
  end


  get "/login/:username/:password" do
    result =
      Postgrex.query!(
        MyApp.DB,
        """
        SELECT id, password_hash
        FROM users
        WHERE username=$1
        """,
        [
          username
        ]
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
            [
              user_id,
              token
            ]
          )


          conn
          |> put_resp_cookie(
            "session",
            token,
            http_only: true
          )
          |> send_resp(
            200,
            "Logged in as #{username}"
          )


        else

          send_resp(
            conn,
            401,
            "Wrong password"
          )

        end


      [] ->

        send_resp(
          conn,
          404,
          "User not found"
        )

    end
  end


  # No dynamic :name in the route anymore!
  get "/profile" do
    # Fetch the query parameter ?username=... from the URL
    username = Map.get(conn.params, "username")
    token = conn.cookies["session"]
  
    if token == nil do
      send_resp(
        conn,
        401,
        "Not logged in"
      )
    else
      result =
        Postgrex.query!(
          MyApp.DB,
          """
          SELECT users.username, users.created_at
          FROM users
          JOIN sessions
          ON users.id = sessions.user_id
          WHERE sessions.token=$1
          """,
          [
            token
          ]
        )
  
      case result.rows do
        [[name, created]] ->
          case name do 
            [username] ->
              send_resp(
                conn,
                200,
                """
                Profile
  
                Username: #{username}
                Created: #{created}
                """
              )
            [] ->
              send_resp(
                conn,
                403,
                ~s(<img src="https://wcti12.com/resources/media/61beaa02-ddd0-4d19-a040-edf2da650e47-large16x9_massage.jpg">)
              )
        [] ->
          send_resp(
            conn,
            401,
            "Invalid session"
          )
      end
    end
  end



  match _ do
    send_resp(
      conn,
      404,
      "Not Found"
    )
  end
end
