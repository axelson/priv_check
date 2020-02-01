defmodule PrivCheckTest do
  use ExUnit.Case, async: true
  doctest PrivCheck

  test "README.md version is up to date" do
    app = :priv_check
    app_version = Application.spec(app, :vsn) |> to_string()
    readme = File.read!("README.md")
    [_, readme_version] = Regex.run(~r/{:#{app}, "(.+)".*}/, readme)
    assert Version.match?(app_version, readme_version)
  end
end
