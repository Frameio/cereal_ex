defmodule Cereal.AssociationNotLoadedError do
  defexception [:message]

  def exception(opts) do
    msg = """
      The #{opts[:rel]} relationship returned %Ecto.Association.NotLoaded{}.
      Please pre-fetch the relationship before serialization or override the
      #{opts[:name]}/2 function in your serializer.
    """

    %Cereal.AssociationNotLoadedError{message: msg}
  end
end
