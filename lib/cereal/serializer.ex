defmodule Cereal.Serializer do
  @moduledoc """
  The Serializer for defining serializers in an opionated way that isn't as complex
  or verbose as JSON API.

  ## Usage example:

    defmodule PostSerializer do
      use Cereal.Serializer

      attributes [:id, :name, :published_state]
      has_one :author, serializer: AuthorSerializer

      def published_state(entity) do
        entity.published_at
        |> case do
          true  -> "published"
          false -> "draft"
        end
      end
    end
  """

  alias Cereal.Utils

  defmacro __using__(_) do
    quote do
      @attributes []
      @relations []

      import Cereal.Serializer, only: [
        attributes: 1, has_many: 2, has_one: 2
      ]

      unquote(define_default_id())
      unquote(define_default_type(__CALLER__.module))
      unquote(define_default_attributes())
      unquote(define_default_relationships())
      unquote(define_default_preload())

      @before_compile Cereal.Serializer
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def __relations,  do: @relations
      def __attributes, do: @attributes
    end
  end

  defp define_default_id do
    quote do
      def id(data, _conn), do: Map.get(data, :id)
      defoverridable [id: 2]
    end
  end

  defp define_default_type(module) do
    type_for_module = Utils.module_to_type(module)

    quote do
      def type(), do: unquote(type_for_module)
      def type(_, _), do: type()
      defoverridable [type: 2]
    end
  end

  defp define_default_attributes do
    quote do
      def attributes(struct, _conn) do
        __MODULE__.__attributes()
        |> Enum.map(&({&1, apply(__MODULE__, &1, [struct])}))
        |> Enum.into(%{})
      end
      defoverridable [attributes: 2]
    end
  end

  defp define_default_relationships do
    quote do
      def relationships(struct, _) do
        __MODULE__.__relations()
        |> Enum.map(fn {_, name, opts} -> {name, opts} end)
        |> Enum.into(%{})
      end
      defoverridable [relationships: 2]
    end
  end

  defp define_default_preload do
    quote do
      def preload(data, conn, _include_opts), do: data
      defoverridable [preload: 3]
    end
  end

  defmacro attributes(attrs) do
    quote bind_quoted: [attrs: attrs] do
      @attributes @attributes ++ attrs

      for attr <- attrs do
        has_function? = :erlang.function_exported(__MODULE__, attr, 1)

        def unquote(attr)(m) do
          # For each attribute, see if there is a function exported on the
          # module with a /1 arity, otherwise fallback to grabbing from the
          # entity passed in.
          unquote(has_function?)
          |> case do
            true  -> apply(__MODULE__, unquote(attr), [m])
            false -> Map.get(m, unquote(attr))
          end
        end
        defoverridable [{attr, 1}]
      end
    end
  end

  defmacro has_one(name, opts) do
    normalized_opts = normalize_relationship_opts(opts, __CALLER__)

    quote do
      @relations [{:has_one, unquote(name), unquote(normalized_opts)} | @relations]
      unquote(Cereal.Serializer.default_relationship_fun(name, opts))
    end
  end

  defmacro has_many(name, opts) do
    normalized_opts = normalize_relationship_opts(opts, __CALLER__)

    quote do
      @relations [{:has_many, unquote(name), unquote(normalized_opts)} | @relations]
      unquote(Cereal.Serializer.default_relationship_fun(name, opts))
    end
  end

  @doc false
  def default_relationship_fun(name, opts) do
    quote bind_quoted: [name: name, opts: opts] do
      def unquote(name)(struct) do
        Cereal.Serializer.get_relationship_data(struct, unquote(name), unquote(opts))
      end
      defoverridable [{name, 1}]
    end
  end

  @doc false
  @error Cereal.AssociationNotLoadedError
  def get_relationship_data(struct, name, opts) do
    struct
    |> Map.get(name)
    |> case do
      %{__struct__: Ecto.Association.NotLoaded} -> raise @error, rel: name, opts: opts
      relations -> relations
    end
  end

  defp normalize_relationship_opts(opts, _) do
    quote do
      unquote(opts) |> Enum.into(%{})
    end
  end
end
