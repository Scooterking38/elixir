defmodule MyApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :my_app,
      version: "0.1.0",
      elixir: "~> 1.16",
      deps: deps()
    ]
  end

  def application do
    [
      mod: {MyApp, []},
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:plug_cowboy, "~> 2.7"},
      {:postgrex, "~> 0.22"},
      {:argon2_elixir, "~> 4.0"}
    ]
  end
end
