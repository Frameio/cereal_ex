defmodule Cereal.Builders.Error do
  @type t :: %__MODULE__{}
  defstruct [:title, :code, :detail, :source, {:meta, %{}}]

  def build(%{data: %Ecto.Changeset{}} = context), do: build_errors_from_changeset(context)

  def build(%{data: data} = context) when is_list(data) do
    data
    |> Enum.map(fn error ->
      context |> Map.put(:data, error) |> build()
    end)
  end

  def build(context) do
    attrs = with_serializer_context(context)
    struct(__MODULE__, attrs)
  end

  defp build_errors_from_changeset(%{data: cs} = context) do
    cs.errors
    |> Enum.map(fn field ->
      context |> Map.put(:data, field) |> format_ecto_error()
    end)
  end

  defp format_ecto_error(%{data: {field, {message, vals}}} = context) do
    message =
      Enum.reduce(vals, message, fn {key, value}, acc ->
        case key do
          :type -> acc
          _ -> String.replace(acc, "%{#{key}}", to_string(value))
        end
      end)

    %{context | data: {field, message}} |> format_ecto_error()
  end

  defp format_ecto_error(%{data: {field, message}, serializer: serializer} = context) do
    %__MODULE__{
      title: message,
      source: field,
      detail: serializer.error_detail(context.data),
      code: serializer.error_code(message),
      meta: serializer.error_metadata(message, context.conn)
    }
  end

  defp with_serializer_context(%{data: data, serializer: serializer, conn: conn}) do
    data
    |> Map.put(:detail, serializer.error_detail(data))
    |> Map.put(:meta, serializer.error_metadata(data, conn))
    |> Map.put(:code, serializer.error_code(data.title))
  end
end
