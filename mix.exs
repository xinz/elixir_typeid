defmodule Typeid.MixProject do
  use Mix.Project

  @source_url "https://github.com/xinz/elixir_typeid"

  def project do
    [
      app: :elixir_typeid,
      version: "0.2.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      docs: docs(),
      description: description(),
      package: package()
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
      {:crockford_base32, "~> 0.8"},
      {:uniq, "~> 0.6"},
      {:ecto, "~> 3.0", optional: true},
      {:jason, "~> 1.3", optional: true},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp docs() do
    [
      main: "readme",
      source_url: @source_url,
      formatter_opts: [gfm: true],
      extras: [
        "README.md"
      ]
    ]
  end

  defp description() do
    "An Elixir implementation of TypeID."
  end

  defp package do
    [
      files: ["lib", "mix.exs", "README.md", "LICENSE.md"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url
      }
    ]
  end

end
