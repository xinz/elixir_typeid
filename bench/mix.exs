defmodule Bench.MixProject do
  use Mix.Project

  # Since this issue https://github.com/elixir-lang/elixir/pull/12007,
  # require elixir 1.14+ for this benchmark.
  def project do
    [
      app: :bench,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:benchee, "~> 1.0", only: :dev, runtime: false},
      #{:elixir_typeid, path: "../", override: true},
      {:elixir_typeid, path: "./.."},
      {:typeid_elixir, "~> 0.6.0", only: :dev},
      {:ecto, "~> 3.10"}
    ]
  end
end
