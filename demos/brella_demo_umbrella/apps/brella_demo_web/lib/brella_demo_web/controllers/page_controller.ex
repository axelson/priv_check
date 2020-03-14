defmodule BrellaDemoWeb.PageController do
  use BrellaDemoWeb, :controller

  # IO.inspect(Mix.Project.config(), label: "Mix.Project.config()")

  def index(conn, _params) do
    BrellaDemo.NonPublic.a_function()
    render(conn, "index.html")
  end
end
