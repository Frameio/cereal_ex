defmodule Cereal.Formatters.AttributesTest do
  use ExUnit.Case

  alias Cereal.Builders.{Base, Entity}
  alias Cereal.Formatters.Attributes

  describe "#format/1" do
    setup [:setup_base]

    test "It will format a single entity into a map with attrs, id and _type", %{base: base} do
      entity = %Entity{id: 1, type: "user", attributes: %{name: "Test"}}
      base = %{base | data: entity}
      expected = %{id: 1, _type: "user", name: "Test"}

      assert Attributes.format(base) == expected
    end

    test "It will format a list of entities with their id, attrs and types", %{base: base} do
      entities = [
        %Entity{id: 1, type: "user", attributes: %{name: "Test"}},
        %Entity{id: 2, type: "user", attributes: %{name: "Another"}}
      ]

      base = %{base | data: entities}

      expected = [
        %{id: 1, _type: "user", name: "Test"},
        %{id: 2, _type: "user", name: "Another"}
      ]

      assert Attributes.format(base) == expected
    end
  end

  def setup_base(_) do
    [base: %Base{metadata: %{}}]
  end
end
