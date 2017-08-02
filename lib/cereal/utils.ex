defmodule Cereal.Utils do

  @doc """
  Given a the name of a serializer, will return a string
  that represents the type of the entity being processed.
  """
  def module_to_type(module) do
    module
    |> Module.split()
    |> List.last()
    |> String.replace("Serializer", "")
    |> String.replace("View", "")
    |> String.downcase()
  end

  @doc """
  Given a set of included relations, will return a normalized list
  of child relations.
  """
  @spec normalize_includes(String.t) :: Keyword.t
  def normalize_includes(include) do
    include
    |> String.split(",")
    |> normalize_include_paths()
  end

  defp normalize_include_paths(paths), do: normalize_include_paths(paths, [])
  defp normalize_include_paths([], normalized), do: normalized
  defp normalize_include_paths([path | paths], normalized) do
    normalized =
      path
      |> String.split(".")
      |> normalize_relationship_path()
      |> deep_merge_relationship_paths(normalized)

    normalize_include_paths(paths, normalized)
  end

  defp normalize_relationship_path([]), do: []
  defp normalize_relationship_path([rel | rest]) do
    Keyword.put([], String.to_atom(rel), normalize_relationship_path(rest))
  end

  defp deep_merge_relationship_paths(left, right), do: Keyword.merge(left, right, &deep_merge_relationship_paths/3)
  defp deep_merge_relationship_paths(_, left, right), do: deep_merge_relationship_paths(left, right)
end
