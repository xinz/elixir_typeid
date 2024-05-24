defmodule CaseRegex do
  @reg ~r/^([a-z]([a-z_]{0,61}[a-z])?)?$/

  def verify(input) do
    Regex.match?(@reg, input)
  end
end

defmodule CasePattern do
  def verify(input) do
    Typeid.Prefix.valid?(input)
  end
end

Benchee.run(
  %{
    "Small case with regex" => fn -> CaseRegex.verify("e1_wme") end,
    "Small case with pattern match" => fn -> CasePattern.verify("e1_wme") end
  },
  print: [fast_warning: false],
  time: 10,
  memory_time: 2
)

Benchee.run(
  %{
    "Medium case with regex" => fn -> CaseRegex.verify("eewmouwuiwme") end,
    "Medium case with pattern match" => fn -> CasePattern.verify("eewmouwuiwme") end
  },
  print: [fast_warning: false],
  time: 10,
  memory_time: 2
)

Benchee.run(
  %{
    "Large case overlength with regex" => fn -> CaseRegex.verify("eewmouwuiwmenwbwmaosxqwisasmoweqjxasmallqeniwswyteqwnczxmsnjdssasasawqwqxasiccxuweqwdsa") end,
    "Large case overlength with pattern match" => fn -> CasePattern.verify("eewmouwuiwmenwbwmaosxqwisasmoweqjxasmallqeniwswyteqwnczxmsnjdssasasawqwqxasiccxuweqwdsa") end
  },
  print: [fast_warning: false],
  time: 10,
  memory_time: 2
)

Benchee.run(
  %{
    "Large case contains \"_\" with regex" => fn -> CaseRegex.verify("eewmouwuiwmenwbwmaosxq_wisasmoweqjxasmallqeniwswyteqwnczxmsnjdssasasawqwqxasiccxuweqwdsa") end,
    "Large case contains \"_\" with pattern match" => fn -> CasePattern.verify("eewmouwuiwmenwbwmaosxq_wisasmoweqjxasmallqeniwswyteqwnczxmsnjdssasasawqwqxasiccxuweqwdsa") end
  },
  print: [fast_warning: false],
  time: 10,
  memory_time: 2
)
