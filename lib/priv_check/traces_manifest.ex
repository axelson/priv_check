# TODO: Rename this to PrivCheck.TracesManifest
defmodule PrivCheck.TracesManifest do
  @moduledoc false

  # Stores compilation tracer calls on disk so that warnings are generated even
  # when a given module was compiled previously

  # Tracks which modules have been seen on this run (not restored from manifest file)
  @seen_table __MODULE__.SeenTable

  # Tracks the compiler tracing traces that have been seen so far
  @traces_table __MODULE__.TracesTable

  # @type trace :: {caller :: module(), trace_type, any()}
  @type trace :: any()
  @type trace_type :: :alias_reference | :function_call | :macro_call

  defmodule Traces do
    defstruct alias_references: [], remote_function_calls: [], remote_macro_calls: []
  end

  @spec start_link :: GenServer.on_start()
  def start_link(_opts \\ nil) do
    result = GenServer.start_link(__MODULE__, nil, name: __MODULE__)

    case result do
      {:ok, _pid} -> clear_seen_table()
      {:error, {:already_started, _pid}} -> clear_seen_table()
      _ -> nil
    end

    result
  end

  def init(nil) do
    :ets.new(@seen_table, [
      :set,
      :public,
      :named_table,
      read_concurrency: true,
      write_concurrency: true
    ])

    case read_manifest() do
      :ok -> nil
      _ -> build_manifest()
    end

    {:ok, %{}}
  end

  @spec add_trace(module(), trace_type(), trace()) :: any()
  def add_trace(caller, trace_type, trace) do
    register_seen_module(caller)
    :ets.insert(@traces_table, {caller, trace_type, trace})
  end

  defp register_seen_module(caller) do
    if :ets.insert_new(@seen_table, {caller}) do
      # If this is the first time we're seeing the caller than that means the
      # caller is being recompiled and we need to delete any current calls
      # associated with the caller
      :ets.delete(@traces_table, caller)
    end
  end

  def flush(_app_modules) do
    # TODO: Prune the traces based on the app modules here for more performance.
    # Pruning is currently implemented in the ReferenceChecker

    :ets.delete_all_objects(@seen_table)
    :ok = :ets.tab2file(@traces_table, manifest_path_charlist())
  end

  def traces do
    initial = %Traces{alias_references: [], remote_function_calls: [], remote_macro_calls: []}

    :ets.tab2list(@traces_table)
    |> Enum.reduce(initial, fn
      {_caller, :alias_reference, trace}, acc ->
        update_in(acc.alias_references, fn traces -> [trace | traces] end)

      {_caller, :function_call, trace}, acc ->
        update_in(acc.remote_function_calls, fn traces -> [trace | traces] end)

      {_caller, :macro_call, trace}, acc ->
        update_in(acc.remote_macro_calls, fn traces -> [trace | traces] end)
    end)
  end

  defp read_manifest do
    path = manifest_path_charlist()

    unless PrivCheck.Mix.stale_manifest?(path) do
      {:ok, _table} = :ets.file2tab(path)

      :ok
    end
  rescue
    _ -> nil
  end

  defp build_manifest do
    table_opts = [:named_table, :public, :duplicate_bag, write_concurrency: true]
    :ets.new(@traces_table, table_opts)
  end

  defp clear_seen_table do
    :ets.delete_all_objects(@seen_table)
  end

  defp manifest_path_charlist() do
    # TODO: This manifest path should include the priv-check version
    PrivCheck.Mix.manifest_path("priv_check.traces")
    |> String.to_charlist()
  end
end
