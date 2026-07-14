defmodule MyApp do
  def main do
    url = System.get_env("DATABASE_URL")

    IO.puts("Connecting...")

    uri = URI.parse(url)

    IO.inspect(
      %{
        scheme: uri.scheme,
        host: uri.host,
        path: uri.path
      },
      label: "Parsed URL"
    )

    {:ok, pid} =
      Postgrex.start_link(
        hostname: uri.host,
        username: uri.userinfo |> String.split(":") |> hd(),
        password: uri.userinfo |> String.split(":") |> List.last(),
        database: String.trim_leading(uri.path, "/"),
        ssl: true
      )

    result = Postgrex.query!(pid, "SELECT NOW()", [])

    IO.inspect(result.rows)
  end
end
