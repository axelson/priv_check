defmodule PrivCheckExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :priv_check_example,
      version: "0.1.0",
      elixir: "~> 1.9",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      compilers: [:priv_check] ++ Mix.compilers()
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
      {:priv_check, path: "../..", runtime: false},
      {:example_dep, path: "example_dep"}
    ]
  end
end
