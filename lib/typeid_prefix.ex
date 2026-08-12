defmodule Typeid.Prefix do
  @moduledoc false

  @type t :: String.t() | nil

  @spec valid?(t()) :: boolean()
  def valid?(nil), do: true
  def valid?(<<>>), do: true
  def valid?(input) when is_binary(input) and byte_size(input) > 63, do: false

  def valid?(<<first, rest::binary>>)
      when first in ?a..?z and byte_size(rest) <= 62 do
    valid_tail?(rest)
  end

  def valid?(_), do: false

  defguardp is_valid_character?(character)
            when character in ?a..?z or character == ?_

  defp valid_tail?(<<>>), do: true
  defp valid_tail?(<<?_>>), do: false

  defp valid_tail?(<<character, rest::binary>>)
       when is_valid_character?(character) do
    valid_tail?(rest)
  end

  defp valid_tail?(_), do: false
end
