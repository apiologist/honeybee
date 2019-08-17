defmodule Honeybee.MixProject do
  use Mix.Project

  def project do
    [
      app: :honeybee,
      version: "0.1.0",
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: [],
      start_permanent: Mix.env() == :prod,
      build_embedded: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      dialyzer: [
        flags: [:unmatched_returns, :error_handling, :race_conditions, :underspecs]
      ],
      name: "Honeybee",
      source_url: "https://github.com/apiologist/honeybee",
      description: """
        Honeybee is an exteremely fast and small router.
      """
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application, do: []

  def elixirc_paths(:test), do: ["lib", "test"]
  def elixirc_paths(:benchmark), do: ["lib", "benchmark"]
  def elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, ">= 1.7.0"},
      {:ex_doc, "~> 0.19", only: :dev},
      {:phoenix, "~> 1.4.9", only: :benchmark},
      {:benchee, "~> 1.0.1", only: :benchmark},
      {:benchee_html, "~> 1.0", only: :benchmark}
    ]
  end

  defp docs do
    [
      main: "introduction",
      extra_section: "GUIDES",
      formatters: ["html"],
      groups_for_modules: [],
      extras: [
        "guides/honeybee/introduction.md",
        "guides/honeybee/routing.md"
      ],
      groups_for_extras: [Honeybee: ~r/guides\/honeybee\/.?/]
    ]
  end

  defp package do
    [
      maintainers: ["apiologist"],
      licenses: ["MIT"],
      links: %{github: "https://github.com/apiologist/honeybee"},
      files: ~w(lib mix.exs README.md LICENSE)
    ]
  end
end
