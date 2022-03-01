defmodule OpentelemetryAbsintheTest.ResolveInstrumentation do
  use ExUnit.Case
  alias AbsinthePlug.Test.Schema
  require Record

  doctest OpentelemetryAbsinthe.ResolveInstrumentation

  for {name, spec} <- Record.extract_all(from_lib: "opentelemetry/include/otel_span.hrl") do
    Record.defrecord(name, spec)
  end

  @query """
  query($isbn: String!) {
    book(isbn: $isbn) {
      title
      author {
        name
        age
      }
    }
  }
  """

  @nested_query """
  query($isbn: String!) {
    book(isbn: $isbn) {
      title
      author {
        name
        age
      }
      comments
    }
  }
  """

  setup do
    Application.delete_env(:opentelemetry_absinthe, :trace_options)
    OpentelemetryAbsinthe.Instrumentation.teardown()
    OpentelemetryAbsinthe.ResolveInstrumentation.teardown()
    OpentelemetryAbsinthe.BatchInstrumentation.teardown()
    :otel_batch_processor.set_exporter(:otel_exporter_pid, self())
  end

  describe "resolve field tracing" do
    test "able to trace root query field data" do
      OpentelemetryAbsinthe.ResolveInstrumentation.setup()
      {:ok, _} = Absinthe.run(@query, Schema, variables: %{"isbn" => "A1"})
      assert_receive {:span, data = span(attributes: attributes)}, 5000

      assert [
               "graphql.field.name"
             ] = attributes |> keys() |> Enum.sort()

      assert data(attributes)["graphql.field.name"] == "book"
      assert span(data, :name) == "absinthe graphql resolve book"
    end

    test "able to trace root query + additional resolving field data" do
      OpentelemetryAbsinthe.ResolveInstrumentation.setup()
      {:ok, _} = Absinthe.run(@nested_query, Schema, variables: %{"isbn" => "A1"})
      assert_receive {:span, data1 = span(attributes: attributes)}, 5000
      assert_receive {:span, data2 = span(attributes: attributes)}, 5000

      spans = [data1, data2]

      assert Enum.any?(spans, fn data ->
               data(span(data, :attributes))["graphql.field.name"] == "book" and
                 span(data, :name) == "absinthe graphql resolve book"
             end)

      assert Enum.any?(spans, fn data ->
               data(span(data, :attributes))["graphql.field.name"] == "comments" and
                 span(data, :name) == "absinthe graphql resolve comments"
             end)
    end
  end

  defp keys(attributes_record), do: attributes_record |> elem(4) |> Map.keys()
  defp data(attributes_record), do: attributes_record |> elem(4)
end
