defmodule Typeid.Suffix do
  @moduledoc false

  alias Typeid.Base32

  @spec generate() :: String.t()
  def generate() do
    uuid7 = Uniq.UUID.uuid7(:raw)

    # Typeid.Base32 is configured with the lowercase TypeID alphabet.
    Base32.encode(<<0::size(2), uuid7::bitstring>>)
  end

  @spec uuid(suffix :: String.t()) :: {:ok, Uniq.UUID.info()} | :error
  def uuid(suffix) do
    with {:ok, <<0::size(2), bits::bitstring>>} <- Base32.decode(suffix),
         {:ok, uuid} <- Uniq.UUID.parse(bits) do
      {:ok, uuid}
    else
      _ ->
        :error
    end
  end

  @spec valid?(suffix :: String.t()) :: boolean()
  def valid?(<<first, rest::binary>>)
      when first in ?0..?7 and byte_size(rest) == 25 do
    valid_characters?(rest)
  end

  def valid?(_), do: false

  defguardp is_valid_character?(character)
            when character in ?0..?9 or character in ?a..?h or character in ?j..?k or
                   character in ?m..?n or character in ?p..?t or character in ?v..?z

  defp valid_characters?(<<>>), do: true

  defp valid_characters?(<<character, rest::binary>>)
       when is_valid_character?(character) do
    valid_characters?(rest)
  end

  defp valid_characters?(_), do: false
end
