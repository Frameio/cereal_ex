defmodule Cereal.Builders.ErrorTest do
  use ExUnit.Case

  alias Cereal.Builders.Error
  alias Cereal.Context

  defmodule BaseErrorSerializer do
    use Cereal.ErrorSerializer
  end

  defmodule CustomErrorSerializer do
    use Cereal.ErrorSerializer

    def error_detail(_), do: "custom"
    def error_code(_), do: :something
    def error_metadata(_, _), do: %{custom: true}
  end

  describe "#build/1" do
    setup [:setup_context]

    test "it will build an error from a map", %{context: context} do
      data = %{title: "is required", detail: "field is required", source: "field"}
      context = %{context | data: data, serializer: BaseErrorSerializer}
      expected = %Error{title: "is required", detail: "field is required", source: "field", code: :required}

      assert Error.build(context) == expected
    end

    test "it will build a list of errors", %{context: context} do
      data = [
        %{title: "is required", detail: "field is required", source: "field"},
        %{title: "is required", detail: "field is required", source: "field"},
      ]
      context = %{context | data: data, serializer: BaseErrorSerializer}
      expected = [
        %Error{title: "is required", detail: "field is required", source: "field", code: :required},
        %Error{title: "is required", detail: "field is required", source: "field", code: :required}
      ]

      assert Error.build(context) == expected
    end

    test "it will add custom properties from the serializer", %{context: context} do
      data = %{title: "is required", detail: "field is required", source: "field"}
      context = %{context | data: data, serializer: CustomErrorSerializer}
      expected = %Error{title: "is required", detail: "custom", source: "field", code: :something, meta: %{custom: true}}

      assert Error.build(context) == expected
    end

    test "it will correctly build ecto changeset errors", %{context: context} do
      data = %Ecto.Changeset{errors: [{:name, "is required"}]}
      context = %{context | data: data, serializer: BaseErrorSerializer}
      expected = [
        %Error{title: "is required", detail: "name is required", source: :name, code: :required}
      ]

      assert Error.build(context) == expected
    end
  end

  def setup_context(_) do
    [context: %Context{opts: [], conn: %{}}]
  end
end
