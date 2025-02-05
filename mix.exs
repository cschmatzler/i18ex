defmodule Idiom.MixProject do
  use Mix.Project

  def project do
    [
      app: :idiom,
      description: "Modern internationalization library",
      version: "0.7.0",
      elixir: "~> 1.14",
      compilers: [:leex, :yecc] ++ Mix.compilers(),
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs(),
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.html": :test,
        "coveralls.json": :test
      ],
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:decimal, "~> 2.1"},
      {:jason, "~> 1.0"},
      {:nimble_options, "~> 1.0"},
      {:req, "~> 0.5"},
      {:credo, "~> 1.7", only: [:dev, :test]},
      {:ex_doc, "~> 0.37", only: :dev},
      {:excoveralls, "~> 0.18", only: :test},
      {:styler, "~> 1.1", only: [:dev, :test], runtime: false}
    ]
  end

  defp package do
    [
      name: "idiom",
      licenses: ["MIT"],
      maintainers: ["Christoph Schmatzler"],
      links: %{"GitHub" => "https://github.com/cschmatzler/idiom"}
    ]
  end

  defp docs do
    [
      main: "Idiom",
      extras: ["CHANGELOG.md"] ++ Path.wildcard("guides/**"),
      groups_for_extras: [
        Guides: Path.wildcard("guides/**")
      ]
    ]
  end
end
