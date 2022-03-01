defmodule OpentelemetryAbsinthe do
  @moduledoc """
  OpentelemetryAbsinthe is an opentelemetry instrumentation library for Absinthe
  """

  def setup() do
    OpentelemetryAbsinthe.Instrumentation.setup()
    OpentelemetryAbsinthe.ResolveInstrumentation.setup()
    OpentelemetryAbsinthe.BatchInstrumentation.setup()
  end
end
