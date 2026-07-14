defmodule MyApp.Router do
  use Plug.Router

  plug :match
  plug :dispatch


  get "/" do
    send_resp(conn, 200, """
    Routes:

    /signup/name/password
    /login/name/password
    /profile/name
    """)
  end


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
          [
            username,
            hash
          ]
        )

        "Created #{username}"

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
        SELECT password_hash
        FROM users
        WHERE username=$1
        """,
        [
          username
        ]
      )

    case result.rows do
      [[hash]] ->
        if Argon2.verify_pass(password, hash) do
          send_resp(
            conn,
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


  get "/profile/:username" do
    result =
      Postgrex.query!(
        MyApp.DB,
        """
        SELECT username, created_at
        FROM users
        WHERE username=$1
        """,
        [
          username
        ]
      )

    case result.rows do
      [[name, created]] ->
        send_resp(
          conn,
          200,
          """
          Username: #{name}
          Created: #{created}
          """
        )

      [] ->
        send_resp(
          conn,
          404,
          "No profile"
        )
    end
  end


  match _ do
    send_resp(
      conn,
      404,
      "Not found"
    )
  end
end
