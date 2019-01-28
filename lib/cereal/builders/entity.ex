defmodule Cereal.Builders.Entity do
  @type t :: %__MODULE__{}
  defstruct [:id, :type, :attributes, {:rels, %{}}]

  def build(%{data: data} = context) when is_list(data) do
    data |> Enum.map(fn entity ->
      context
      |> Map.put(:data, entity)
      |> build()
    end)
  end

  def build(%{serializer: serializer} = context) do
    context = Map.put(context, :data, serializer.transform(context.data))

    %__MODULE__{
      id: serializer.id(context.data, context.conn),
      type: serializer.type(context.data, context.conn),
      attributes: attributes(context),
      rels: relationships(context),
    }
  end

  defp attributes(%{serializer: serializer} = context) do
    serializer.attributes(context.data, context.conn)
    |> Enum.map(fn {key, fnc} -> {key, fnc.(context.data, context.conn)} end)
    |> Enum.into(%{})
    |> filter_attributes(context)
  end

  defp relationships(%{serializer: serializer} = context) do
    serializer.relationships(context.data, context.opts)
    |> Enum.map(&maybe_fetch_relationship(context, &1))
    |> Enum.into(%{})
  end

  defp maybe_fetch_relationship(context, {name, rel_opts}) do
    relation =
      should_include_relation?(context.opts, name, rel_opts)
      |> case do
        true  -> relation(context, name, rel_opts)
        false -> nil
      end

    {name, relation}
  end

  defp relation(%{serializer: serializer} = context, name, rel_opts) do
    apply(serializer, name, [context.data])
    |> build_relation_entity(context, name, rel_opts)
  end

  defp build_relation_entity(nil, _, _, _), do: nil
  defp build_relation_entity(relation, context, name, rel_opts) do
    context 
    |> Map.put(:serializer, rel_opts.serializer)
    |> Map.put(:opts, with_relationship_includes(context.opts, name))
    |> Map.put(:data, relation)
    |> build()
  end

  defp with_relationship_includes(%{include: includes} = opts, name) when is_list(includes),
    do: %{opts | include: includes[name]}
  defp with_relationship_includes(opts, _), do: opts

  # We include the option when the following is true:
  # 1) The relation options have `include: true`
  # 2) The `include` option is passed in and includes the resource
  defp should_include_relation?(_, _, %{include: true}), do: true
  defp should_include_relation?(%{include: included}, name, _) when is_list(included),
    do: included[name] |> is_list()
  defp should_include_relation?(_, _, %{include: false}), do: false
  defp should_include_relation?(_, _, _), do: true

  defp filter_attributes(attrs, %{serializer: serializer, opts: %{fields: fields}} = context) when is_list(fields) do
    type = serializer.type(context.data, context.conn) |> String.to_atom()
    do_filter_attributes(attrs, {:take, fields[type]})
  end
  defp filter_attributes(attrs, %{serializer: serializer, opts: %{excludes: fields}} = context) when is_list(fields) do
    type = serializer.type(context.data, context.conn) |> String.to_atom()
    do_filter_attributes(attrs, {:drop, fields[type]})
  end
  defp filter_attributes(attrs, _), do: attrs

  defp do_filter_attributes(attrs, nil), do: attrs
  defp do_filter_attributes(attrs, {:take, fields}) when is_list(fields),
    do: Map.take(attrs, fields)
  defp do_filter_attributes(attrs, {:drop, fields}) when is_list(fields),
    do: Map.drop(attrs, fields)
  defp do_filter_attributes(attrs, {action, fields}) when is_binary(fields) do
    fields = fields |> String.split(",") |> Enum.map(&String.to_atom/1)
    do_filter_attributes(attrs, {action, fields})
  end
end
