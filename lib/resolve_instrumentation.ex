defmodule OpentelemetryAbsinthe.ResolveInstrumentation do
  @moduledoc """
  Module for automatic instrumentation of Absinthe resolution, field level.

  It works by listening to [:absinthe, :resolve, :operation, :start/:stop] telemetry events,
  which are emitted by Absinthe only since v1.5; therefore it won't work on previous versions.

  (you can still call `OpentelemetryAbsinthe.ResolveInstrumentation.setup()` in your application startup
  code, it just won't do anything.)
  """

  alias OpenTelemetry.Span
  require Record

  @tracer_id __MODULE__

  @default_config [
    resolve_span_name: "absinthe graphql resolve"
  ]

  def setup(instrumentation_opts \\ []) do
    config =
      @default_config
      |> Keyword.merge(Application.get_env(:opentelemetry_absinthe, :trace_options, []))
      |> Keyword.merge(instrumentation_opts)
      |> Enum.into(%{})

    :telemetry.attach(
      {__MODULE__, :resolution_start},
      [:absinthe, :resolve, :field, :start],
      &__MODULE__.handle_resolution_start/4,
      config
    )

    :telemetry.attach(
      {__MODULE__, :resolution_stop},
      [:absinthe, :resolve, :field, :stop],
      &__MODULE__.handle_resolution_stop/4,
      config
    )
  end

  def teardown do
    :telemetry.detach({__MODULE__, :resolution_start})
    :telemetry.detach({__MODULE__, :resolution_stop})
  end

  def handle_resolution_start(_event_name, _measurements, metadata, config) do
    field_name = metadata.resolution.definition.name
    attributes = [{"graphql.field.name", field_name}]

    OpentelemetryTelemetry.start_telemetry_span(@tracer_id, "#{config.resolve_span_name} #{field_name}", metadata, %{
      kind: :server,
      attributes: attributes
    })
  end

  def handle_resolution_stop(_event_name, _measurements, data, config) do
    ctx = OpentelemetryTelemetry.set_current_telemetry_span(@tracer_id, data)

    OpentelemetryTelemetry.end_telemetry_span(@tracer_id, data)
  end

  # Surprisingly, that doesn't seem to by anything in the stdlib to conditionally
  # put stuff in a list / keyword list.
  # This snippet is approved by José himself:
  # https://elixirforum.com/t/creating-list-adding-elements-on-specific-conditions/6295/4?u=learts
  defp put_if(list, false, _), do: list
  defp put_if(list, true, value), do: [value | list]
end
