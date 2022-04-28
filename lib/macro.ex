defmodule OpentelemetryAbsinthe.Macro do
    defmacro put_if(map_data, clause, key_expr, value_expr) do
        quote do
          if unquote(clause) do
            Map.put(unquote(map_data), unquote(key_expr), unquote(value_expr))
          else
            unquote(map_data)
          end
        end
    end
end
