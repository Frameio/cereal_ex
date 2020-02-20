defmodule CerealTest do
  use ExUnit.Case
  doctest Cereal

  defmodule UserSerializer do
    use Cereal.Serializer
    attributes [:name, :property_that_needs_context]

    def property_that_needs_context(_, %{assigns: %{article_name: article_name, comment_id: comment_id}}) do
      "My context is #{article_name} and comment with id #{comment_id}"
    end
    def property_that_needs_context(_, _), do: ""
  end

  defmodule CommentSerializer do
    use Cereal.Serializer
    attributes [:text, :property_that_needs_context]
    has_one :user, serializer: UserSerializer, include: true

    def property_that_needs_context(_, %{assigns: %{article_name: article_name, request_id: request_id}}) do
      "My context is #{article_name} and I still have access to the request id #{request_id}"
    end
    def property_that_needs_context(_, %{assigns: %{article_name: article_name}}) do
      "My context is #{article_name}"
    end

    def assigns(%{id: id}, _) do
      %{comment_id: id}
    end
    def assigns(data, conn), do: super(data, conn)
  end

  defmodule ArticleSerializer do
    use Cereal.Serializer
    attributes [:name]
    has_one :author, serializer: UserSerializer, include: false
    has_many :comments, serializer: CommentSerializer, include: true

    def assigns(%{name: name}, _) do
      %{article_name: name}
    end
    def assigns(data, conn), do: super(data, conn)
  end

  defmodule BlogSerializer do
    use Cereal.Serializer
    attributes [:name]
    has_many :articles, serializer: ArticleSerializer, include: true

    def name(_, %{assigns: %{request_id: request_id}}) do
      "I still have access to request_id #{request_id}"
    end
    def name(_, _) do
      "I am a fallback prop"
    end
  end

  describe "#serialize/3" do
    test "will include nested entities that are requested via includes params" do
      user = %TestModel.User{id: 1, name: "John Doe"}
      article = %TestModel.Article{id: 1, name: "Article 1", author: user}
      blog = %TestModel.Blog{id: 1, articles: [article]}

      result = Cereal.serialize(BlogSerializer, blog, %{}, include: "articles.author")

      assert result == %{
        _type: "blog",
        id: 1,
        name: "I am a fallback prop",
        articles: [
          %{
            _type: "article",
            id: 1,
            name: "Article 1",
            author: %{
              _type: "user",
              id: 1,
              name: "John Doe",
              property_that_needs_context: ""
            }
          }
        ]
      }
    end

    test "will include only the specified attributes for a given record" do
      user = %TestModel.User{id: 1, name: "John Doe"}
      article = %TestModel.Article{id: 1, name: "Article 1", author: user}
      blog = %TestModel.Blog{id: 1, articles: [article]}

      result =
        Cereal.serialize(BlogSerializer, blog, %{},
          include: "articles.author",
          fields: [user: "name", article: "id"]
        )

      assert result == %{
        _type: "blog",
        id: 1,
        name: "I am a fallback prop",
        articles: [
          %{
            _type: "article",
            id: 1,
            author: %{
              _type: "user",
              id: 1,
              name: "John Doe"
            }
          }
        ]
      }
    end

    test "will exclude the specified attributes for a given record" do
      user = %TestModel.User{id: 1, name: "John Doe"}
      article = %TestModel.Article{id: 1, name: "Article 1", author: user}
      blog = %TestModel.Blog{id: 1, articles: [article]}

      result =
        Cereal.serialize(BlogSerializer, blog, %{},
          include: "articles.author",
          excludes: [user: "name,property_that_needs_context", article: "name"]
        )

      assert result == %{
        _type: "blog",
        id: 1,
        name: "I am a fallback prop",
        articles: [
          %{
            _type: "article",
            id: 1,
            author: %{
              _type: "user",
              id: 1
            }
          }
        ]
      }
    end

    test "will allow assigning data to the conn on relationships" do
      author = %TestModel.User{id: 1, name: "Johnny Test"}
      comments1 = [%TestModel.Comment{id: 1, text: "A comment", user: author}]
      comments2 = [%TestModel.Comment{id: 2, text: "A comment", user: author}]
      article1 = %TestModel.Article{id: 1, name: "Article 1", comments: comments1, author: author}
      article2 = %TestModel.Article{id: 2, name: "Article 2", comments: comments2, author: author}
      blog = %TestModel.Blog{id: 1, articles: [article1, article2]}
      serialized = Cereal.serialize(BlogSerializer, blog, %Plug.Conn{assigns: %{request_id: 22}})
      assert serialized.name === "I still have access to request_id 22"

      serialized_article1 = Enum.find(serialized.articles, fn a -> a.name == "Article 1" end)
      [serialized_comment1] = serialized_article1.comments
      # comment for article 1 and its preloaded user both have access to the correct conn assigns from article 1
      assert serialized_comment1.property_that_needs_context == "My context is Article 1 and I still have access to the request id 22"
      assert serialized_comment1.user.property_that_needs_context == "My context is Article 1 and comment with id 1"

      serialized_article2 = Enum.find(serialized.articles, fn a -> a.name == "Article 2" end)
      [serialized_comment2] = serialized_article2.comments
      # comment for article 2 and its preloaded user both have access to the correct conn assigns from article 2
      assert serialized_comment2.property_that_needs_context == "My context is Article 2 and I still have access to the request id 22"
      assert serialized_comment2.user.property_that_needs_context == "My context is Article 2 and comment with id 2"
    end

    test "will not error on a conn that has assigns but is not a Plug.Conn" do
      author = %TestModel.User{id: 1, name: "Johnny Test"}
      comments1 = [%TestModel.Comment{id: 1, text: "A comment", user: author}]
      comments2 = [%TestModel.Comment{id: 2, text: "A comment", user: author}]
      article1 = %TestModel.Article{id: 1, name: "Article 1", comments: comments1, author: author}
      article2 = %TestModel.Article{id: 2, name: "Article 2", comments: comments2, author: author}
      blog = %TestModel.Blog{id: 1, articles: [article1, article2]}
      serialized = Cereal.serialize(BlogSerializer, blog, %{assigns: %{request_id: 22}})
      assert serialized.name === "I still have access to request_id 22"

      serialized_article1 = Enum.find(serialized.articles, fn a -> a.name == "Article 1" end)
      [serialized_comment1] = serialized_article1.comments
      # comment for article 1 and its preloaded user both have access to the correct conn assigns from article 1
      assert serialized_comment1.property_that_needs_context == "My context is Article 1 and I still have access to the request id 22"
      assert serialized_comment1.user.property_that_needs_context == "My context is Article 1 and comment with id 1"

      serialized_article2 = Enum.find(serialized.articles, fn a -> a.name == "Article 2" end)
      [serialized_comment2] = serialized_article2.comments
      # comment for article 2 and its preloaded user both have access to the correct conn assigns from article 2
      assert serialized_comment2.property_that_needs_context == "My context is Article 2 and I still have access to the request id 22"
      assert serialized_comment2.user.property_that_needs_context == "My context is Article 2 and comment with id 2"
    end

    test "will not error on empty conn" do
      author = %TestModel.User{id: 1, name: "Johnny Test"}
      comments1 = [%TestModel.Comment{id: 1, text: "A comment", user: author}]
      comments2 = [%TestModel.Comment{id: 2, text: "A comment", user: author}]
      article1 = %TestModel.Article{id: 1, name: "Article 1", comments: comments1, author: author}
      article2 = %TestModel.Article{id: 2, name: "Article 2", comments: comments2, author: author}
      blog = %TestModel.Blog{id: 1, articles: [article1, article2]}
      serialized = Cereal.serialize(BlogSerializer, blog, %{})
      assert serialized.name === "I am a fallback prop"

      serialized_article1 = Enum.find(serialized.articles, fn a -> a.name == "Article 1" end)
      [serialized_comment1] = serialized_article1.comments
      # comment for article 1 and its preloaded user both have access to the correct conn assigns from article 1
      assert serialized_comment1.property_that_needs_context == "My context is Article 1"
      assert serialized_comment1.user.property_that_needs_context == "My context is Article 1 and comment with id 1"

      serialized_article2 = Enum.find(serialized.articles, fn a -> a.name == "Article 2" end)
      [serialized_comment2] = serialized_article2.comments
      # comment for article 2 and its preloaded user both have access to the correct conn assigns from article 2
      assert serialized_comment2.property_that_needs_context == "My context is Article 2"
      assert serialized_comment2.user.property_that_needs_context == "My context is Article 2 and comment with id 2"
    end
  end
end
