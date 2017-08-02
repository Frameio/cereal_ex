defmodule Cereal.Builders.Errors do
  @type t :: %__MODULE__{}
  defstruct [:title, :status, :errors]

  alias Cereal.Builders.Error

  @spec build(Cereal.Context.t) :: Errors.t
  def build(%{serializer: serializer} = context) do
    struct(Errors, %{})
    |> Map.put(:title, serializer.title(context.conn))
    |> Map.put(:errors, Error.build(context))
    |> Map.put(:status, serializer.status(context.conn))
  end
end
