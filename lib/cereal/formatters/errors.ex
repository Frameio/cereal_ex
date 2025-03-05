defmodule Cereal.Formatters.Errors do
  @behaviour Cereal.Formatter

  def format(%Cereal.Builders.Errors{} = base) do
    %{message: base.title, code: base.status, errors: format_errors(base.errors)}
  end

  defp format_errors(errors) when is_list(errors), do: errors |> Enum.map(&format_error/1)
  defp format_errors(error), do: [format_error(error)]

  defp format_error(%Cereal.Builders.Error{} = error) do
    %{field: error.source, detail: error.detail, title: error.title, code: error.code} |> maybe_attach_metadata(error)
  end

  defp maybe_attach_metadata(attrs, %{meta: %{}}), do: attrs

  defp maybe_attach_metadata(attrs, %{meta: meta}) do
    attrs |> Map.put(:meta, meta)
  end
end
