defmodule Honeybee.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :honeybee,
      version: @version,
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: [
        main: "introduction",
        extra_section: "GUIDES",
        formatters: ["html"],
        groups_for_modules: [],
        extras: [
          "guides/honeybee/introduction.md",
          "guides/honeybee/routing.md"
        ],
        groups_for_extras: [Honeybee: ~r/guides\/honeybee\/.?/]
      ],
      package: package(),
      dialyzer: [
        flags: [:unmatched_returns, :error_handling, :race_conditions, :underspecs]
      ],
      name: "Honeybee",
      source_url: "https://github.com/sfinnman/honeybee",
      description: """
      Blazing fast Phoenix style plug router.
      """
    ]
  end

  def aliases do
    [
      bench: &bench/1
    ]
  end

  defp bench(args) do
    Mix.Task.run("run", args)
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # def elixirc_paths(:bench), do: ["lib", "benchmarks/lib"]
  def elixirc_paths(:test), do: ["lib", "test"]
  def elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.7.1"},
      {:benchee, "~> 0.13", only: :dev},
      {:benchee_html, "~> 0.4", only: :dev},
      {:phoenix, "~> 1.4.0", only: :dev},
      {:dialyxir, "~> 0.4", only: :dev},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      maintainers: ["Simon Finnman"],
      licenses: ["GNU"],
      links: %{github: "https://github.com/sfinnman/honeybee"},
      files: ~w(lib mix.exs README.md .formatter.exs)
    ]
  end
end
