defmodule Cereal.ErrorSerializer do
  @moduledoc """
  DSL to provide the ability to create custom error serializers
  """
  defmacro __using__(_) do
    quote do
      unquote(define_default_title())
      unquote(define_default_status())
      unquote(define_default_error_funs())
    end
  end

  defp define_default_title do
    quote do
      def title(conn), do: Cereal.ErrorSerializer.title(conn)
      defoverridable [title: 1]
    end
  end

  defp define_default_status do
    quote do
      def status(conn), do: Cereal.ErrorSerializer.status(conn)
      defoverridable [status: 1]
    end
  end

  defp define_default_error_funs do
    quote do
      def error_detail(data), do: Cereal.ErrorSerializer.error_detail(data)
      def error_code(message), do: Cereal.ErrorSerializer.error_code(message)
      def error_metadata(message, conn), do: Cereal.ErrorSerializer.error_metadata(message, conn)
      defoverridable [error_detail: 1, error_code: 1, error_metadata: 2]
    end
  end

  @doc false
  def title(_), do: "There was a problem processing your request"

  @doc false
  def status(%{status: status}), do: status

  @doc false
  def error_metadata(_, _), do: %{}

  @doc false
  def error_detail({field, message}), do: "#{field} #{message}"
  def error_detail(%{detail: msg}), do: msg

  @doc false
  def error_code("is required"), do: :required
  def error_code(_), do: :invalid
end
