defmodule Cereal.Formatters.ErrorsTest do
  use ExUnit.Case
  alias Cereal.Builders.{Errors, Error}
  alias Cereal.Formatters.Errors, as: Subject

  describe "#format/1" do
    setup [:setup_errors]

    test "It will format an errors builder correctly", %{errors: errors} do
      expected = %{
        message: "There was a problem processing your request",
        code: 422,
        errors: [%{
          code: :required,
          field: "title",
          detail: "title is required"
        }]
      }

      error = %Error{title: "is required", source: "title", detail: "title is required", code: :required}
      errors = %{errors | errors: [error]}

      assert Subject.format(errors) == expected
    end
  end

  def setup_errors(_) do
    [errors: %Errors{title: "There was a problem processing your request", status: 422}]
  end
end
