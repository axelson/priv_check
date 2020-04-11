defmodule PrivCheck.Config do
  @config_file_name ".priv_check.exs"

  defstruct ignored_files: [], ignore_references_to_modules: []

  def from_file_system do
    case File.read(@config_file_name) do
      {:error, :enoent} -> build_config(nil)
      {:ok, contents} -> PrivCheck.ExsLoader.parse(contents, true) |> build_config()
    end
  end

  def ignore_references_to_module(%__MODULE__{} = config, module) do
    MapSet.member?(config.ignore_references_to_modules, module)
  end

  def ignore_calls_from_file(%__MODULE__{} = config, file) do
    MapSet.member?(config.ignored_files, file)
  end

  defp build_config({:ok, config_contents}) do
    ignored_files = Map.get(config_contents, :ignored_files, [])
    ignore_references_to_modules = Map.get(config_contents, :ignore_references_to_modules, [])

    %__MODULE__{
      ignored_files: MapSet.new(ignored_files),
      ignore_references_to_modules: MapSet.new(ignore_references_to_modules)
    }
  end

  defp build_config(_) do
    build_config({:ok, %{}})
  end
end
