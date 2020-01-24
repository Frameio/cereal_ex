defmodule Cereal.Builders.EntityTest do
  use ExUnit.Case

  alias Cereal.Builders.Entity
  alias Cereal.Context

  defmodule UserSerializer do
    use Cereal.Serializer
    attributes [:name, :not_an_attr]
    def not_an_attr(_, _), do: true
  end

  defmodule TransformedSerializer do
    use Cereal.Serializer
    attributes [:name]
    def transform(data) do
      %{name: data.name <> "-1"}
    end
  end

  defmodule CommentSerializer do
    use Cereal.Serializer
    attributes [:text]
    has_one :user, serializer: UserSerializer
  end

  defmodule ArticleSerializer do
    use Cereal.Serializer
    attributes [:name]
    has_one :author, serializer: UserSerializer
    has_many :comments, serializer: CommentSerializer
  end

  defmodule ConditionalCommentSerializer do
    use Cereal.Serializer
    attributes [:text]
    has_one :user, serializer: UserSerializer, include: false

    def type(_, _), do: "comment"
  end

  defmodule DefaultCommentRelationSerializer do
    use Cereal.Serializer
    attributes [:text]
    has_one :author, serializer: UserSerializer, default: TestModel.User, include: true
  end

  defmodule EmbedSerializer do
    use Cereal.Serializer
    attributes [:text]

    embeds_one :comment, serializer: CommentSerializer
  end

  describe "#build/1" do
    setup [:setup_context]

    test "it will build an entity with an id, type and attributes", %{context: context} do
      data     = %TestModel.User{id: 1, name: "Dummy"}
      context  = %{context | data: data, serializer: UserSerializer}
      expected = %Entity{id: 1, type: "user", attributes: %{name: "Dummy", not_an_attr: true}}

      assert Entity.build(context) == expected
    end

    test "it will build a list of entities with an id, type and attributes", %{context: context} do
      data     = [%TestModel.User{id: 1, name: "Dummy"}, %TestModel.User{id: 2, name: "Another"}]
      context  = %{context | data: data, serializer: UserSerializer}
      expected = [
        %Entity{id: 1, type: "user", attributes: %{name: "Dummy", not_an_attr: true}},
        %Entity{id: 2, type: "user", attributes: %{name: "Another", not_an_attr: true}}
      ]

      assert Entity.build(context) == expected
    end

    test "it will build an entity with a single has_one relation", %{context: context} do
      user = %TestModel.User{id: 1, name: "Johnny Test"}
      data = %TestModel.Comment{id: 1, user: user, text: "A comment"}
      context = %{context | data: data, serializer: CommentSerializer}

      expected_user = %Entity{id: 1, type: "user", attributes: %{name: "Johnny Test", not_an_attr: true}}
      expected = %Entity{id: 1, type: "comment", attributes: %{text: "A comment"}, rels: %{user: expected_user}}

      assert Entity.build(context) == expected
    end

    test "it will build an entity with a relation that is nil", %{context: context} do
      data = %TestModel.Comment{id: 1, text: "A comment"}
      context = %{context | data: data, serializer: CommentSerializer}
      expected = %Entity{id: 1, type: "comment", attributes: %{text: "A comment"}, rels: %{user: nil}}

      assert Entity.build(context) == expected
    end

    test "it will skip non-included entities", %{context: context} do
      user = %TestModel.User{id: 1, name: "Test User"}
      data = %TestModel.Comment{id: 1, text: "A comment", user: user}
      context = %{context | data: data, serializer: ConditionalCommentSerializer}

      expected = %Entity{id: 1, attributes: %{text: "A comment"}, rels: %{user: nil}, type: "comment"}

      assert Entity.build(context) == expected
    end

    test "it will include non-included entities when forced", %{context: context} do
      context = %{context | opts: %{include: [user: []]}}
      user = %TestModel.User{id: 1, name: "Test User"}
      data = %TestModel.Comment{id: 1, text: "A comment", user: user}
      context = %{context | data: data, serializer: ConditionalCommentSerializer}

      expected_user = %Entity{attributes: %{name: "Test User", not_an_attr: true}, id: 1, rels: %{}, type: "user"}
      expected = %Entity{id: 1, attributes: %{text: "A comment"}, rels: %{user: expected_user}, type: "comment"}

      assert Entity.build(context) == expected
    end

    test "it will conditionally include fields", %{context: context} do
      data     = %TestModel.User{id: 1, name: "Dummy"}
      opts     = %{fields: [user: "name"]}
      context  = %{context | data: data, serializer: UserSerializer, opts: opts}
      expected = %Entity{id: 1, type: "user", attributes: %{name: "Dummy"}}

      assert Entity.build(context) == expected
    end

    test "it will conditionally drop excluded fields", %{context: context} do
      data     = %TestModel.User{id: 1, name: "Dummy"}
      opts     = %{excludes: [user: "name"]}
      context  = %{context | data: data, serializer: UserSerializer, opts: opts}
      expected = %Entity{id: 1, type: "user", attributes: %{not_an_attr: true}}

      assert Entity.build(context) == expected
    end

    test "It will serialize embeds", %{context: context} do
      data = %TestModel.Post{
        id: 3,
        text: "some_text",
        comment: %TestModel.Comment{
          id: 2,
          text: "a comment",
          user: %TestModel.User{
            id: 1,
            name: "Dummy"
          }
        }
      }
      context  = %{context | data: data, serializer: EmbedSerializer, opts: []}
      expected = %Entity{
        id: 3,
        type: "embed",
        attributes: %{
          text: "some_text",
          comment: %{
            id: 2,
            _type: "comment",
            text: "a comment",
            user: %{
              id: 1,
              name: "Dummy",
              not_an_attr: true,
              _type: "user"
            }
          }
        }
      }

      assert Entity.build(context) == expected
    end

    test "it will build a deeply nested entity", %{context: context} do
      user = %TestModel.User{id: 1, name: "Johnny User"}
      comments = [%TestModel.Comment{id: 1, user: user, text: "A comment"}]
      article = %TestModel.Article{id: 1, name: "Article 1", comments: comments}
      context = %{context | data: article, serializer: ArticleSerializer}

      expected = %Entity{
        id: 1,
        type: "article",
        attributes: %{name: "Article 1"},
        rels: %{
          author: nil,
          comments: [%Entity{
            id: 1,
            type: "comment",
            attributes: %{text: "A comment"},
            rels: %{
              user: %Entity{
                id: 1,
                type: "user",
                attributes: %{
                  name: "Johnny User",
                  not_an_attr: true
                }
              }
            }
          }]
        }
      }

      assert Entity.build(context) == expected
    end

    test "it will modify attributes with a transform function", %{context: context} do
      user = %TestModel.User{id: 1, name: "Johnny"}
      context = %{context | data: user, serializer: TransformedSerializer}

      expected = %Entity{attributes: %{name: "Johnny-1"}, type: "transformed"}

      assert Entity.build(context) == expected
    end
  end

  def setup_context(_) do
    [context: %Context{opts: %{}, conn: %{}}]
  end
end
