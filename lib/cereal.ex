defmodule Cereal do
  alias Cereal.Builders.{Base, Errors}
  alias Cereal.Formatter

  defmodule Context do
    defstruct [:data, :conn, :opts, :serializer]
  end

  def serialize(serializer, data, conn \\ %{}, opts \\ []) do
    %Context{data: data, conn: conn, opts: opts, serializer: serializer}
    |> Base.build()
    |> Formatter.format()
    |> serializer.transform()
  end

  def serialize_errors(serializer, data, conn \\ %{}, opts \\ []) do
    %Context{data: data, conn: conn, opts: opts, serializer: serializer}
    |> Errors.build()
    |> Formatter.format()
  end
end
