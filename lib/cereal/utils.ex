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
    |> underscore()
  end

  @doc """
  Given a set of included relations, will return a normalized list
  of child relations. Implicitly filters out any relation in the normalized tree
  that cannot be safely converted from a binary string to an atom.
  """
  @spec normalize_includes(String.t()) :: Keyword.t()
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
    case string_to_atom(rel) do
      nil -> []
      key -> Keyword.put([], key, normalize_relationship_path(rest))
    end
  end

  defp deep_merge_relationship_paths(left, right), do: Keyword.merge(left, right, &deep_merge_relationship_paths/3)
  defp deep_merge_relationship_paths(_, left, right), do: deep_merge_relationship_paths(left, right)

  @doc """
  Takes a keyword list of comma separated strings keyed by serializer name and
  converts the strings into lists of atoms. Implicitly removes any binary string
  that cannot be safely converted to an atom.

  Example:

      # Input
      [user: "name,id,location", comment: "type"]

      # Output
      [user: [:name, :id, :location], comment: [:type]]
  """
  @spec build_fields_list([{atom(), String.t()}] | String.t()) :: [{atom(), [atom()]}]
  def build_fields_list([{_, _} | _] = fields) do
    Enum.map(fields, fn {key, fields_str} -> {key, build_fields_list(fields_str)} end)
  end

  def build_fields_list(fields) when is_binary(fields) do
    fields
    |> String.split(",")
    |> Enum.map(&string_to_atom/1)
    |> Enum.filter(&(&1 != nil))
  end

  def build_fields_list(_), do: []

  # Attempts to convert an arbitrary String.t() into an existing atom. If an
  # exception is raised, or a non-binary is passed in, we simply return `nil`.
  @spec string_to_atom(String.t()) :: atom() | nil
  defp string_to_atom(str) when is_binary(str) do
    try do
      String.to_existing_atom(str)
    rescue
      _ -> nil
    end
  end

  defp string_to_atom(atom) when is_atom(atom), do: atom
  defp string_to_atom(_), do: nil

  @doc false
  def underscore(""), do: ""

  def underscore(<<h, t::binary>>) do
    <<to_lower_char(h)>> <> do_underscore(t, h)
  end

  defp do_underscore(<<h, t, rest::binary>>, _) when h in ?A..?Z and not (t in ?A..?Z or t == ?.) do
    <<?_, to_lower_char(h), t>> <> do_underscore(rest, t)
  end

  defp do_underscore(<<h, t::binary>>, prev) when h in ?A..?Z and prev not in ?A..?Z do
    <<?_, to_lower_char(h)>> <> do_underscore(t, h)
  end

  defp do_underscore(<<?., t::binary>>, _) do
    <<?/>> <> underscore(t)
  end

  defp do_underscore(<<h, t::binary>>, _) do
    <<to_lower_char(h)>> <> do_underscore(t, h)
  end

  defp do_underscore(<<>>, _) do
    <<>>
  end

  defp to_lower_char(char) when char in ?A..?Z, do: char + 32
  defp to_lower_char(char), do: char
end
