defmodule OpentelemetryAbsinthe.Helpers do
  @moduledoc """
  OpenTelemetry-friendly alternatives of Absinthe.Resolution.Helpers functions
  Some of the standard absinthe resolution helpers, like `batch` or `async`,
  are not "opentelemetry-friendly": the resolvers, when invoked, lose the active span
  and break the trace propagation.
  This module defines compatible alternatives that can be used in the same way,
  but don't lose the trace information.
  """

  alias Absinthe.Middleware.Batch
  require OpenTelemetry.Tracer

  @doc """
  Works like Absinthe.Resolution.Helpers.batch, but preserves the active span.
  The function supplied to the `batch` helper is executed in a Task by Absinthe,
  which means that the erlang opentelemetry SDK would lose track of the currently
  active span, because they are kept in a pdict.
  To work around this, you can just replace `batch` with `traced_batch`,
  and the active span will be automatically passed and reset as the active one
  inside the batch function.
  """
  @spec traced_batch(Batch.batch_fun(), any(), Batch.post_batch_fun()) ::
          {:middleware, Batch, term}
  @spec traced_batch(
          Batch.batch_fun(),
          any(),
          Batch.post_batch_fun(),
          opts :: [{:timeout, pos_integer}]
        ) :: {:middleware, Batch, term}

  def traced_batch(batch_key, batch_data, post_batch_fn) do
    traced_batch(batch_key, batch_data, post_batch_fn, [])
  end

  def traced_batch({module, func}, batch_data, post_batch_fn, opts) do
    traced_batch({module, func, []}, batch_data, post_batch_fn, opts)
  end

  def traced_batch({module, func, param}, batch_data, post_batch_fn, opts) do
    span_ctx = OpentelemetryAbsinthe.Registry.get_absinthe_execution_span() || OpenTelemetry.Tracer.current_span_ctx()
    batch_key = {__MODULE__, :batch_fun_wrapper, {{module, func, param}, span_ctx}}
    batch_config = {batch_key, batch_data, post_batch_fn, opts}
    {:middleware, Absinthe.Middleware.Batch, batch_config}
  end

  defp get_batch_function_as_string(batch_fun)
  defp get_batch_function_as_string({module, func}), do: "#{module} #{func}"
  defp get_batch_function_as_string({module, func, first_arg}) when is_atom(first_arg), do: "#{module} #{func} #{inspect(first_arg)}"
  defp get_batch_function_as_string({module, func, _first_arg}), do: "#{module} #{func}"

  @doc """
  Wrapper around the "real" batch function used by `batch_keep_span`
  Takes the passed span and sets it as the active one, then calls the original
  batch function with the original parameter.
  """
  def batch_fun_wrapper({{module, func, param}, span}, aggregate) do
    OpenTelemetry.Tracer.set_current_span(span)
    batch_id = get_batch_function_as_string({module, func, param})
    OpenTelemetry.Tracer.with_span "traced-batch-execution #{batch_id}" do
      apply(module, func, [param, aggregate])
    end
  end

  @doc "Simple dropin replacement for `Absinthe.Resolution.Helpers.async`, add tracing to async"
  def traced_async(fun, opts \\ []) do
    span_ctx = OpenTelemetry.Tracer.current_span_ctx()

    decorated_fun = fn ->
      OpenTelemetry.Tracer.set_current_span(span_ctx)
      OpenTelemetry.Tracer.with_span "traced-async-execution" do
        fun.()
      end
    end

    Absinthe.Resolution.Helpers.async(decorated_fun, opts)
  end
end
