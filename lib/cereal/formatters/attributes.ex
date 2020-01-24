defmodule Cereal.Formatters.Attributes do
  @behaviour Cereal.Formatter

  def format(%Cereal.Builders.Base{data: data}), do: format_data(data)

  defp format_data(data) when is_list(data), do: data |> Enum.map(&format_data/1)
  defp format_data(%Cereal.Builders.Entity{} = entity) do
    entity.attributes
    |> Map.put(:id, entity.id)
    |> Map.put(:_type, entity.type)
    |> Map.merge(format_relations(entity.rels))
  end

  defp format_relations(relations) do
    relations
    |> Enum.filter(fn {_, rel_or_rels} -> rel_or_rels != nil end)
    |> Enum.map(fn {name, rel_or_rels} -> {name, format_data(rel_or_rels)} end)
    |> Enum.into(%{})
  end
end
