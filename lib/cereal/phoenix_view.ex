defmodule Cereal.PhoenixView do
  defmacro __using__(_) do
    module = __CALLER__.module
    quote do
      use Cereal.Serializer

      def render("index.json" <> _, data) do
        Cereal.PhoenixView.render(unquote(module), data)
      end

      def render("show.json" <> _, data) do
        Cereal.PhoenixView.render(unquote(module), data)
      end

      def render("errors.json" <> _, data) do
        Cereal.PhoenixView.render_errors(unquote(module), data)
      end
    end
  end

  def render(serializer, data) do
    Cereal.serialize(serializer, data[:data], data[:conn], data[:opts] || [])
  end

  def render_errors(serializer, data) do
    errors = data[:data] || data[:errors]
    Cereal.serialize_errors(serializer, errors, data[:conn], data[:opts])
  end
end
