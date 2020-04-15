# The job of this module is to log all of the compilation traces for later
# analysis
defmodule PrivCheck.Tracer do
  @moduledoc false

  use Agent
  require Logger

  defmodule State do
    @moduledoc """
    Recorded traces
    """

    defstruct [:alias_references, :remote_function_calls, :remote_macro_calls]

    @type t :: %__MODULE__{
            alias_references: nil | String.t()
          }
  end

  @type alias_reference ::
          {module(), file_name :: String.t(), line :: pos_integer(), caller :: module()}

  @type remote_function_call ::
          {mfa(), caller :: module(), file_name :: String.t(), line :: pos_integer()}
  @type remote_macro_call ::
          {mfa(), caller :: module(), file_name :: String.t(), line :: pos_integer()}

  @ignored_modules [
    :elixir_def,
    :elixir_module,
    :elixir_utils,
    Kernel.LexicalTracker,
    Kernel.Typespec,
    Kernel.Utils,
    # The fact that this is needed seems to point to a possible bug in compiler tracing
    Phoenix.Router.Scope
  ]

  @ignored_mfa [
    {Module, :__get_attribute__, 3},
    {Module, :__put_attribute__, 4},
    {RuntimeError, :exception, 1}
  ]

  def start_link(_) do
    initial_state = %State{
      alias_references: [],
      remote_function_calls: [],
      remote_macro_calls: []
    }

    Agent.start_link(fn -> initial_state end, name: __MODULE__)
  end

  def trace({:remote_function, meta, module, name, arity}, env) do
    cond do
      ignore_module?(module) ->
        :ok

      ignore_mfa?({module, name, arity}) ->
        :ok

      # Code without a line number is generated from a macro (often from a def inside of a __using__ macro)
      meta[:line] == nil ->
        :ok

      true ->
        mfa = {module, name, arity}
        register_remote_function_call({mfa, env.module, env.file, meta[:line]})
        :ok
    end
  end

  def trace({:remote_macro, meta, module, name, arity}, env) do
    mfa = {module, name, arity}
    register_remote_macro_call({mfa, env.module, env.file, meta[:line]})
    :ok
  end

  def trace({:alias_reference, meta, module}, env) do
    unless ignore_module?(module) do
      register_alias_reference({module, env.file, meta[:line], env.module})
    end

    :ok
  end

  def trace(_event, _env) do
    :ok
  end

  @spec register_alias_reference(alias_reference()) :: :ok
  def register_alias_reference(alias_reference) do
    {_module, _file, _line, caller} = alias_reference
    PrivCheck.TracesManifest.add_trace(caller, :alias_reference, alias_reference)

    Agent.update(__MODULE__, fn state ->
      %State{state | alias_references: [alias_reference | state.alias_references]}
    end)
  end

  @spec register_remote_function_call(remote_function_call()) :: :ok
  def register_remote_function_call(remote_function_call) do
    {_mfa, caller, _file, _line} = remote_function_call
    PrivCheck.TracesManifest.add_trace(caller, :function_call, remote_function_call)

    Agent.update(__MODULE__, fn state ->
      %State{state | remote_function_calls: [remote_function_call | state.remote_function_calls]}
    end)
  end

  @spec register_remote_macro_call(remote_macro_call()) :: :ok
  def register_remote_macro_call(remote_macro_call) do
    {_mfa, caller, _file, _line} = remote_macro_call
    PrivCheck.TracesManifest.add_trace(caller, :macro_call, remote_macro_call)

    Agent.update(__MODULE__, fn state ->
      %State{state | remote_macro_calls: [remote_macro_call | state.remote_macro_calls]}
    end)
  end

  for ignored_mod <- @ignored_modules do
    defp ignore_module?(unquote(ignored_mod)), do: true
  end

  defp ignore_module?(_), do: false

  for {mod, fun, arity} <- @ignored_mfa do
    defp ignore_mfa?({unquote(mod), unquote(fun), unquote(arity)}), do: true
  end

  defp ignore_mfa?({_, :__info__, 1}), do: true

  defp ignore_mfa?(_), do: false
end
