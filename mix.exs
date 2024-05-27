defmodule Typeid.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_typeid,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env())
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:crockford_base32, "~> 0.7"},
      {:uniq, "~> 0.6"},
      {:ecto, "~> 3.0", optional: true},
      {:jason, "~> 1.4", only: [:test]}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]
end
