defmodule TypeidCrockfordBase32 do

  def decode(input) do
    base32_decode(input)
  end

  defp base32_decode(input) do
    with {:ok, bits} <- CrockfordBase32.decode_to_bitstring(input),
         <<0::size(2), uuid::bitstring>> <- may_append_padding_with_0(bits) do 
      {:ok, uuid}
    end
  end

  defp may_append_padding_with_0(<<_::size(130)>> = input), do: input
  defp may_append_padding_with_0(input) when bit_size(input) < 130 do
    padding_size = 130-bit_size(input)
    <<input::bitstring, 0::integer-size(padding_size)>>
  end
  defp may_append_padding_with_0(_), do: :error

end

defmodule CrockfordBase32Fixed130Bit do
  use CrockfordBase32,
    bits_size: 130
end

defmodule TypeidCrockfordBase32Fixed do

  def decode(input) do
    {:ok, <<0::size(2), uuid7::bitstring>>} = CrockfordBase32Fixed130Bit.decode(input)
    {:ok, uuid7}
  end

end

Benchee.run(
  %{
    "TypeidCrockfordBase32 decode" => fn -> TypeidCrockfordBase32.decode("01hy3b3hq5fmevjn8me7c4hzdm") end,
    "TypeidCrockfordBase32Fixed decode" => fn -> TypeidCrockfordBase32Fixed.decode("01hy3b3hq5fmevjn8me7c4hzdm") end
  },
  print: [fast_warning: false],
  time: 10,
  memory_time: 2
)
