defmodule MyApp do
  def start do
    Application.ensure_all_started(:plug_cowboy)

    Plug.Cowboy.http(
      MyApp.Router,
      [],
      port: 4000
    )

    IO.puts("Server running on port 4000")

    Process.sleep(:infinity)
  end
end
