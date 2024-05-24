defmodule TypeidPrefixTest do
  use ExUnit.Case

  alias Typeid.Prefix

  test "case with uppercase" do
    assert Prefix.valid?("Abc") == false
    assert Prefix.valid?("aBc") == false
    assert Prefix.valid?("abC") == false
  end

  test "case with underscore" do
    assert Prefix.valid?("_abc") == false
    assert Prefix.valid?("abc_") == false
    assert Prefix.valid?("a_b_c") == true
  end

  test "case with overlength" do
    input = String.pad_leading("abc", 64, "defg")
    assert Prefix.valid?(input) == false
    input = String.pad_leading("abc", 65, "defg")
    assert Prefix.valid?(input) == false
    input = String.pad_leading("abc", 63, "defg")
    assert Prefix.valid?(input) == true
    input = String.pad_leading("ab_", 63, "defg")
    assert Prefix.valid?(input) == false
  end

  test "case with numeric" do
    assert Prefix.valid?("1abc") == false
    assert Prefix.valid?("a_c1") == false
  end

  test "case with unexpected symbols" do
    assert Prefix.valid?("test.pre") == false
    assert Prefix.valid?("test#pre") == false
    assert Prefix.valid?("test@pre") == false
    assert Prefix.valid?("test!pre") == false
    assert Prefix.valid?("test$pre") == false
    assert Prefix.valid?("test%pre") == false
    assert Prefix.valid?("test^pre") == false
    assert Prefix.valid?("   test") == false
  end

  test "case with non-ascii" do
    assert Prefix.valid?("préfix") == false
  end

  test "some proper cases" do
    assert Prefix.valid?("prefixname") == true
    input = String.pad_leading("foo", 63, "abc")
    assert Prefix.valid?(input) == true
  end
end
