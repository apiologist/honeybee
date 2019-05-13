defmodule Honeybee.MixProject do
  use Mix.Project

  def project do
    [
      app: :honeybee,
      version: "0.0.1",
      elixir: "~> 1.8",
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: [],
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
      source_url: "https://github.com/apiologist/honeybee",
      description: """
        Honeybee is an exteremely fast and small router.
      """
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application, do: []

  def elixirc_paths(:test), do: ["lib", "test"]
  def elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug, "~> 1.7.1"},
      {:benchee, "~> 0.13", only: :test},
      {:benchee_html, "~> 0.4", only: :test},
      {:phoenix, "~> 1.4.0", only: :test},
      {:dialyxir, "~> 0.4", only: :test},
      {:ex_doc, "~> 0.19", only: :dev}
    ]
  end

  defp package do
    [
      maintainers: ["apiologist"],
      licenses: ["GNU"],
      links: %{github: "https://github.com/apiologist/honeybee"},
      files: ~w(lib mix.exs README.md)
    ]
  end
end
