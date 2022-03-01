This is a fork of Opentelemetry Absinthe (from original repo):
Main change in this fork are:
- changing instrumentation to use `opentelemetry_telemetry` for better standard behaviour with `absinthe` telemetry event
- delete `helpers` in favour of using telemetry event from `absinthe` directly
- tracing `:absinthe, :resolve, :field, :start/:stop` event and `:absinthe, :middleware, :batch, :start/:stop`

# OpentelemetryAbsinthe

OpentelemetryAbsinthe is a [OpenTelemetry](https://opentelemetry.io) instrumentation library for [Absinthe](https://github.com/absinthe-graphql/absinthe).


# How to use
after adding this project as dependency on `mix.exs` (currently prefered only via git reference)
add `OpentelemetryAbsinthe.setup()` on `application` `start`
```
def start(_type, _args) do
   ...
   OpentelemetryAbsinthe.setup()
   ...
end
```
