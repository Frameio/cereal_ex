defmodule Cereal.SerializerTest do
  use ExUnit.Case

  defmodule TransformSerializer do
    use Cereal.Serializer
    attributes([:text])

    def transform(data) do
      {text, popped} = Map.pop(data, :text)

      popped
      |> Map.put(:transformed, text)
    end
  end

  describe "#serialize/2" do
    test "will transform data" do
      data = %{text: "Arbitrary text"}

      serialized = Cereal.serialize(TransformSerializer, data)

      assert serialized.transformed == data.text
      refute :text in serialized
    end
  end
end
