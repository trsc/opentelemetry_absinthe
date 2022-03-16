defmodule OpentelemetryAbsinthe.HelpersTest do
  use ExUnit.Case
  alias OpentelemetryAbsinthe.Helpers

  describe "get_batch_function_as_string" do
    test "correctly resolve absinthe_ecto" do
      input =
        {Absinthe.Ecto, :perform_batch,
         {ProfileService.Repo, ProfileService.Companies.Schema.CompanyPartner, :ksuid, :financing_agreement, nil,
          "random pid"}}

      output = "absinthe_ecto assoc financing_agreement"
      assert output == Helpers.get_batch_function_as_string(input)
    end

    test "correctly resolve batch_fun_wrappers" do
      input =
        {OpentelemetryAbsinthe.Helpers, :batch_fun_wrapper,
         {{ProfileService.Companies.CompanyPartners, :batch_partner_name, []}, %{}}}

      output = "wrapped Elixir.ProfileService.Companies.CompanyPartners batch_partner_name"
      assert output == Helpers.get_batch_function_as_string(input)
    end

    test "correctly resolve standard 2 arity batch" do
      input = {RandomModule, :random_function}
      output = "Elixir.RandomModule random_function"
      assert output == Helpers.get_batch_function_as_string(input)
    end

    test "correctly resolve standard 3 arity batch" do
      input = {RandomModule, :random_function, %{}}
      output = "Elixir.RandomModule random_function"
      assert output == Helpers.get_batch_function_as_string(input)
    end

    test "correctly resolve 3 arity batch with atom as first argument" do
      input = {RandomModule, :random_function, :random_id}
      output = "Elixir.RandomModule random_function :random_id"
      assert output == Helpers.get_batch_function_as_string(input)
    end
  end
end
