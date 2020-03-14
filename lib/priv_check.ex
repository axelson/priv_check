defmodule PrivCheck do
  @moduledoc """
  Documentation for PrivCheck.
  """
  defdelegate public_fun?(mfa), to: PrivCheck.DocChecker
end
