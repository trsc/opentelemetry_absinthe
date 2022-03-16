defmodule OpentelemetryAbsinthe.Registry do
  def get_absinthe_execution_span() do
    Process.get({__MODULE__, :absinthe_execution_span})
  end

  def put_absinthe_execution_span(value) do
    Process.put({__MODULE__, :absinthe_execution_span}, value)
  end
end
