defmodule PrivCheck.MixProject do
  use Mix.Project

  def project do
    [
      app: :priv_check,
      version: "0.1.0",
      elixir: ">= 1.10.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      docs: docs(),
      dialyzer: dialyzer()
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
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
    ]
  end

  defp elixirc_paths(:test), do: ~w(lib test/support)
  defp elixirc_paths(_), do: ~w(lib)

  defp docs() do
    [
      main: "PrivCheck",
      extras: ["README.md"]
    ]
  end

  defp dialyzer() do
    [
      plt_add_apps: [:mix]
    ]
  end
end
