defmodule Cereal.Builders.Base do
  alias Cereal.Utils
  alias Cereal.Builders.{Entity}

  @type t :: %__MODULE__{}
  defstruct [:data, :page, :metadata]

  @doc """
  Builds a Cereal Base struct that encapsulates the JSON that will be serialized.

  Will correctly handle Scrivener pagination.
  """
  @spec build(Cereal.Context.t()) :: __MODULE__.t()
  def build(context)

  if Code.ensure_loaded?(Scrivener) do
    def build(%{data: %Scrivener.Page{} = page, opts: opts} = context) do
      opts = opts |> Enum.into(%{}) |> Map.put(:page, to_page_options(page))
      build(%{context | data: page.entries, opts: opts})
    end
  end

  def build(%{serializer: serializer, data: data, opts: opts} = context) do
    opts = parse_opts(opts)
    data = serializer.preload(data, context.conn, Map.get(opts, :include, []))
    context = %{context | data: data, opts: opts}

    struct(__MODULE__, %{})
    |> Map.put(:data, Entity.build(context))
    |> Map.put(:metadata, build_metadata(context))
    |> Map.put(:page, build_page(context))
  end

  defp build_page(%{opts: opts}), do: Map.get(opts, :page)
  defp build_metadata(%{opts: opts}), do: Map.get(opts, :metadata)

  defp parse_opts(opts) when is_list(opts), do: opts |> Map.new() |> parse_opts()

  defp parse_opts(opts) when is_map(opts) do
    opts
    |> parse_includes()
    |> parse_fields_list(:fields)
    |> parse_fields_list(:excludes)
  end

  defp parse_opts(_), do: %{}

  defp parse_includes(%{include: include} = opts) when is_binary(include),
    do: %{opts | include: Utils.normalize_includes(include)}

  defp parse_includes(opts), do: opts

  defp parse_fields_list(opts, key) do
    case Map.get(opts, key) do
      nil -> opts
      fields -> Map.put(opts, key, Utils.build_fields_list(fields))
    end
  end

  # Parse a Scrivener.Page into a map we can use
  defp to_page_options(page), do: page |> Map.from_struct() |> Map.drop([:entries])
end
