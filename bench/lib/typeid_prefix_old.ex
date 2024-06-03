defmodule Typeid.Prefix.Old do
  @moduledoc false

  @spec valid?(String.t()) :: boolean()
  def valid?(input), do: do_valid?(input)

  defp do_valid?(""), do: true
  defp do_valid?("_"), do: false
  defp do_valid?(<<"_", _rest::binary>>), do: false
  defp do_valid?(input) when byte_size(input) > 63, do: false
  # ends with "_"
  for i <- 1..62 do
    defp do_valid?(<<_::binary-size(unquote(i)), "_">>), do: false
  end

  for i <- 1..63 do
    {inputs, bodies} =
      Enum.reduce(1..i, {[], []}, fn number, {params, bodies} -> 
        {["c#{number}::8" | params], ["v(c#{number})" | bodies]}
      end)
    i_ast = "<<#{Enum.join(inputs, ",")}>>" |> Code.string_to_quoted!()
    b_ast = Enum.join(bodies, "&&") |> Code.string_to_quoted!()
    defp do_valid?(unquote(i_ast)) do
      unquote(b_ast)
    end
  end
  defp do_valid?(_), do: false

  @compile {:inline, v: 1}
  defp v(char) when char in ?a..?z, do: true
  defp v(?_), do: true
  defp v(_), do: false
end
