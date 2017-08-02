defmodule Cereal.Builders.Base do
  alias Cereal.Utils
  alias Cereal.Builders.{Entity}

  defstruct [:data, :page, :metadata]

  @doc """
  Builds a Cereal Base struct that encapsulates the JSON that will be serialized.

  Will correctly handle Scrievener pagination.
  """
  @spec build(Cereal.Context.t) :: Base.t
  def build(context)
  if Code.ensure_loaded?(Scrivener) do
    def build(%{data: %Scrivener.Page{} = page, opts: opts} = context) do
      opts = opts |> normalize_opts() |> Map.put(:page, to_page_options(page))
      build(%{context | data: page.entries, opts: opts})
    end
  end
  def build(%{serializer: serializer, data: data, opts: opts} = context) do
    opts    = normalize_opts(opts)
    data    = serializer.preload(data, context.conn, Map.get(opts, :include, []))
    context = %{context | data: data, opts: opts}

    struct(Base, %{})
    |> Map.put(:data, Entity.build(context))
    |> Map.put(:metadata, build_metadata(context))
    |> Map.put(:page, build_page(context))
  end

  defp build_page(%{opts: opts}), do: Map.get(opts, :page)
  defp build_metadata(%{opts: opts}), do: Map.get(opts, :metadata)

  defp normalize_opts(opts) when is_list(opts), do: opts |> Enum.into(%{}) |> normalize_opts()
  defp normalize_opts(%{include: include} = opts),
    do: normalize_opts(%{opts | include: Utils.normalize_includes(include)})
  defp normalize_opts(opts), do: opts

  # Parse a Scrivener.Page into a map we can use
  defp to_page_options(page), do: page |> Map.from_struct() |> Map.drop([:entries])
end
