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

      import Cereal.Serializer,
        only: [
          attributes: 1,
          has_many: 2,
          has_one: 2,
          embeds_one: 2
        ]

      unquote(define_default_id())
      unquote(define_default_type(__CALLER__.module))
      unquote(define_default_assigns())
      unquote(define_default_attributes())
      unquote(define_default_relationships())
      unquote(define_default_preload())
      unquote(define_default_transform())

      @before_compile Cereal.Serializer
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def __relations, do: @relations
      def __attributes, do: @attributes
    end
  end

  defp define_default_id do
    quote do
      def id(data, _conn), do: Map.get(data, :id)
      defoverridable id: 2
    end
  end

  defp define_default_transform do
    quote do
      def transform(data, _), do: data
      defoverridable transform: 2
    end
  end

  defp define_default_type(module) do
    type_for_module = Utils.module_to_type(module)

    quote do
      def type(), do: unquote(type_for_module)
      def type(_, _), do: type()
      defoverridable type: 2
    end
  end

  defp define_default_assigns do
    quote do
      def assigns(_data, _conn), do: %{}
      defoverridable assigns: 2
    end
  end

  defp define_default_attributes do
    quote do
      def attributes(struct, conn) do
        __MODULE__.__attributes()
        |> Enum.map(&{&1, fn struct, conn -> apply(__MODULE__, &1, [struct, conn]) end})
        |> Enum.into(%{})
      end

      defoverridable attributes: 2
    end
  end

  defp define_default_relationships do
    quote do
      def relationships(struct, _) do
        __MODULE__.__relations()
        |> Enum.map(fn {_, name, opts} -> {name, opts} end)
        |> Enum.into(%{})
      end

      defoverridable relationships: 2
    end
  end

  defp define_default_preload do
    quote do
      def preload(data, conn, _include_opts), do: data
      defoverridable preload: 3
    end
  end

  defmacro attributes(attrs) do
    quote bind_quoted: [attrs: attrs] do
      @attributes @attributes ++ attrs

      for attr <- attrs do
        def unquote(attr)(m, _), do: Map.get(m, unquote(attr))
        defoverridable [{attr, 2}]
      end
    end
  end

  defmacro embeds_one(name, opts) do
    [serializer: serializer] = expand_serializer_in_place(opts, {:embeds_one, 2}, __CALLER__)

    quote do
      @attributes [unquote(name) | @attributes]
      def unquote(name)(%{unquote(name) => nil}, _), do: nil

      def unquote(name)(%{unquote(name) => model}, conn) do
        Cereal.serialize(unquote(serializer), model, conn)
      end

      defoverridable [{unquote(name), 2}]
    end
  end

  defmacro has_one(name, opts) do
    opts = expand_serializer_in_place(opts, {:has_many, 2}, __CALLER__)
    normalized_opts = normalize_relationship_opts(opts, __CALLER__)

    quote do
      @relations [{:has_one, unquote(name), unquote(normalized_opts)} | @relations]
      unquote(Cereal.Serializer.default_relationship_fun(name, opts))
    end
  end

  defmacro has_many(name, opts) do
    opts = expand_serializer_in_place(opts, {:has_many, 2}, __CALLER__)
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
  def get_relationship_data(struct, name, _opts) do
    struct
    |> Map.get(name)
    |> case do
      %{__struct__: Ecto.Association.NotLoaded} -> nil
      relations -> relations
    end
  end

  defp normalize_relationship_opts(opts, _env) do
    quote do
      unquote(opts) |> Enum.into(%{})
    end
  end

  defp expand_serializer_in_place(opts, alias_context, env) do
    Keyword.update!(opts, :serializer, &expand_alias(&1, alias_context, env))
  end

  defp expand_alias({:__aliases__, _, _} = ast, alias_context, env),
    do: Macro.expand(ast, %{env | function: alias_context})

  defp expand_alias(ast, _alias_context, _env), do: ast
end
