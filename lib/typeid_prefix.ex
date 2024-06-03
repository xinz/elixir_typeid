defmodule Typeid.Prefix do
  @moduledoc false

  @spec valid?(String.t()) :: boolean()
  def valid?(<<>>), do: true
  def valid?(nil), do: true
  def valid?(?_), do: false
  def valid?(<<?_, _rest::binary>>), do: false
  def valid?(input) when byte_size(input) > 63, do: false
  for i <- 1..62 do
    def valid?(<<_::binary-size(unquote(i)), ?_>>), do: false
  end
  def valid?(input) when byte_size(input) <= 63 do
    check(input)
  end
  def valid?(_), do: false

  defguardp is_char_valid?(x) when x in ?a..?z or x == ?_

  defp check(<<>>), do: true
  defp check(<<c::size(8), rest::binary>>) when is_char_valid?(c) do
    check(rest)
  end
  defp check(_), do: false

end
