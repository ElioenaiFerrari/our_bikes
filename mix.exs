defmodule OurBikes.MixProject do
  use Mix.Project

  def project do
    [
      app: :our_bikes,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        main: "OurBikes",
        source_url: "https://github.com/ElioenaiFerrari/our_bikes",
        extras: ["README.md"]
      ],
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {OurBikes.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:faker, "~> 0.18.0", only: [:test, :dev]},
      {:ecto, "~> 3.11"},
      {:ecto_sql, "~> 3.11"},
      {:postgrex, "~> 0.17.5"},
      {:ecto_sqlite3, "~> 0.15.1", only: [:test, :dev]},
      {:ex_doc, "~> 0.31.2", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.drop", "ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"]
    ]
  end
end
