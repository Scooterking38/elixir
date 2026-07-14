defmodule MyApp do
  def main do
    {:ok, pid} =
      Postgrex.start_link(
        url: System.get_env("DATABASE_URL")
      )

    result = Postgrex.query!(pid, "SELECT NOW()", [])

    IO.inspect(result.rows)
  end
end
