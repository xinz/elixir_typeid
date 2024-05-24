defmodule TypeidSuffixTest do
  use ExUnit.Case
  alias Typeid.Suffix

  test "padding zero-bit after base32 decode" do
    suffix = "01hy3b3hq5fmevjn8me7c4hzdm"
    {:ok, uuid} = Suffix.uuid(suffix) 
    assert uuid.version == 7
    assert Uniq.UUID.to_string(uuid, :raw) == <<1, 143, 134, 177, 198, 229, 125, 29, 185, 85, 20, 113, 216, 72, 253, 180>>
  end

  test "calculate zero-bit in last 5-bit of base32 bitstring" do
    suffix = "01hy17nynneqw9j5x3ke3mwtk3"
    {:ok, uuid} = Suffix.uuid(suffix) 
    assert Uniq.UUID.to_string(uuid, :raw) == <<1, 143, 130, 122, 250, 181, 117, 248, 153, 23, 163, 155, 135, 78, 106, 99>>
  end

  test "generate and extract its uuid" do
    test_case = 3

    suffix_list = 
      for _i <- 1..test_case do
        suffix = Suffix.generate()
        assert String.length(suffix) == 26
        {:ok, uuid} = Suffix.uuid(suffix)
        assert uuid.version == 7
        suffix
      end

    assert MapSet.new(suffix_list) |> MapSet.size() == test_case
  end

end
