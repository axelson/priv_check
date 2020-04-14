defmodule PrivCheck.MixProject do
  use Mix.Project

  @version "0.2.1"

  def project do
    [
      app: :priv_check,
      version: @version,
      elixir: ">= 1.10.0",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      elixirc_paths: elixirc_paths(Mix.env()),
      docs: docs(),
      dialyzer: dialyzer(),
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
      {:dialyxir, "~> 1.0", only: :dev, runtime: false},
      {:ex_doc, "~> 0.21", only: :dev, runtime: false},
      {:credo, "~> 1.1", only: [:dev, :test], runtime: false}
    ]
  end

  defp elixirc_paths(:test), do: ~w(lib test/support)
  defp elixirc_paths(_), do: ~w(lib)

  defp docs() do
    [
      main: "PrivCheck",
      extras: ["README.md"],
      source_url: "https://github.com/axelson/priv_check/",
      source_ref: @version
    ]
  end

  defp dialyzer() do
    [
      plt_add_apps: [:mix]
    ]
  end

  defp package() do
    [
      description: "Check for private API usage at compile-time",
      maintainers: ["Jason Axelson"],
      licenses: ["MIT"],
      links: %{
        "Github" => "https://github.com/axelson/priv_check",
        "Changelog" =>
          "https://github.com/axelson/blob/#{@version}/Changelog.md##{
            String.replace(@version, ".", "")
          }"
      }
    ]
  end
end
