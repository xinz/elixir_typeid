defmodule SplitBinary1 do

  def split(str) do
    len = byte_size(str)
    suffix = :binary.part(str, {len, -27})
    prefix = :binary.part(str, {0, len-27})
    match(prefix, suffix)
  end

  defp match(prefix, <<"_"::binary, suffix::binary>>) do
    {prefix, suffix}
  end
  defp match(_prefix, _suffix) do
    :error
  end

end

defmodule SplitBinary2 do

  def split(string) do
    size = byte_size(string)
    prefix = binary_part(string, 0, size-27)
    suffix = binary_part(string, size - 27, 27)
    match(prefix, suffix)
  end

  defp match(prefix, <<"_"::binary, suffix::binary>>) do
    {prefix, suffix}
  end
  defp match(_, _) do
    :error
  end

end
