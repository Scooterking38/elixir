defmodule MyApp do
  def main do
    {:ok, pid} =
      Postgrex.start_link(
        url: Application.fetch_env!(:my_app, :database_url)
      )

    result = Postgrex.query!(pid, "SELECT NOW()", [])

    IO.inspect(result.rows)
  end
end

MyApp.main()
