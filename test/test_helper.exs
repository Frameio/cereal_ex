ExUnit.start()

# Models used for testing
defmodule TestModel.Blog do
  defstruct [:id, :name, :articles]
end

defmodule TestModel.Article do
  defstruct [:id, :name, :author, :comments]
end

defmodule TestModel.User do
  defstruct [:id, :name]
end

defmodule TestModel.Comment do
  defstruct [:id, :user, :text]
end

defmodule TestModel.Post do
  defstruct [:id, :text, :comment]
end
