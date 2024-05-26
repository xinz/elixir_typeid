defmodule Typeid.Suffix do
  @moduledoc false

  alias Typeid.Base32

  @spec generate() :: String.t()
  def generate() do
    uuid7 = Uniq.UUID.uuid7(:raw)
    <<0::size(2), uuid7::bitstring>>
    |> Base32.encode()
    |> String.downcase()
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
  def valid?(suffix) do
    case Base32.decode(suffix) do
      {:ok, _} ->
        true
      _ ->
        false
    end
  end
end
