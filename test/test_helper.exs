ExUnit.start()

# Models used for testing
defmodule TestModel.Article do
  defstruct [:id, :name, :author, :comments]
end

defmodule TestModel.User do
  defstruct [:id, {:name, "a name"}]
end

defmodule TestModel.Comment do
  defstruct [:id, :user, :text]
end
