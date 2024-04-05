defmodule OurBikes.MixProject do
  use Mix.Project

  def project do
    [
      app: :our_bikes,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:faker, "~> 0.18.0", only: :test}
    ]
  end
end