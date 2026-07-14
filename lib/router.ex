defmodule MyApp.Router do
  use Plug.Router

  plug :match
  plug :dispatch


  def db do
    {:ok, pid} =
      Postgrex.start_link(
        url: System.get_env("DATABASE_URL")
      )

    pid
  end


  get "/" do
    send_resp(conn, 200, """
    Routes:

    /signup/name/password
    /login/name/password
    /profile/name
    """)
  end


  get "/signup/:username/:password" do

    hash =
      Argon2.hash_pwd_salt(password)

    Postgrex.query!(
      db(),
      """
      INSERT INTO users(username,password_hash)
      VALUES($1,$2)
      """,
      [
        username,
        hash
      ]
    )

    send_resp(
      conn,
      200,
      "Created #{username}"
    )
  end


  get "/login/:username/:password" do

    result =
      Postgrex.query!(
        db(),
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
          "User does not exist"
        )

    end
  end


  get "/profile/:username" do

    result =
      Postgrex.query!(
        db(),
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
    send_resp(conn,404,"Not found")
  end
end
