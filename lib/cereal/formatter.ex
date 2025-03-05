defmodule Cereal.Formatter do
  @moduledoc """
  Formats the base entities given the `:formatter` specified in the config.
  Defaults to the `Attributes` formatter.
  """

  @doc """
  Given a base entity, format and returns a map or a list
  """
  @callback format(Cereal.Builder.Base.t() | Cereal.Builder.Errors.t()) :: Map.t() | List.t()

  @spec format(Cereal.Builder.Base.t() | Cereal.Builders.Errors.t()) :: map | list
  def format(base), do: apply(formatter(base), :format, [base])

  defp formatter(%Cereal.Builders.Base{}),
    do: Application.get_env(:cereal, :formatter, Cereal.Formatters.Attributes)

  defp formatter(%Cereal.Builders.Errors{}),
    do: Application.get_env(:cereal, :error_formatter, Cereal.Formatters.Errors)
end
