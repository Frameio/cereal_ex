defmodule Cereal.Mixfile do
  use Mix.Project

  @version "1.4.1"

  def project do
    [
      app: :cereal,
      version: @version,
      elixir: "~> 1.5",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      package: package(),
      description: description(),
      deps: deps(),
      docs: docs()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger]]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:ecto, "~> 3.9"},
      {:ex_doc, "~> 0.19", only: :dev},
      {:scrivener, "~> 1.2 or ~> 2.0", optional: true},
      {:plug, "~> 1.12"}
    ]
  end

  defp docs() do
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v#{@version}",
      source_url: "https://github.com/Frameio/cereal_ex"
    ]
  end

  defp description do
    "A generalizable, configurable serialization dsl for elixir"
  end

  defp package do
    [
      maintainers: ["Michael Guarino"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/Frameio/cereal_ex"}
    ]
  end
end
