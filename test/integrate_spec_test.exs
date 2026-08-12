defmodule IntegrateSpecTest do
  use ExUnit.Case
  alias Typeid.Test.JSONReader
  alias Uniq.UUID

  @invalid_cases_path Path.join([__DIR__, "support", "typeid", "spec", "invalid.json"])
  @valid_cases_path Path.join([__DIR__, "support", "typeid", "spec", "valid.json"])
  @external_resource @invalid_cases_path
  @external_resource @valid_cases_path

  for item <- JSONReader.invalid_cases() do
    test "spec invalid - #{item["description"]}" do
      typeid = unquote(item["typeid"])

      assert :error == Typeid.parse(typeid)
      refute Typeid.valid?(typeid)
    end
  end

  for item <- JSONReader.valid_cases() do
    test "spec valid - #{item["name"]} - #{item["prefix"]}" do
      input = unquote(item["typeid"])
      expected_prefix = unquote(item["prefix"])

      assert {:ok, typeid} = Typeid.parse(input)
      assert typeid.prefix == if(expected_prefix == "", do: nil, else: expected_prefix)
      assert Typeid.to_string(typeid) == input
      assert Typeid.valid?(typeid)
      assert Typeid.valid?(input)

      if unquote(item["name"]) not in ["max-valid", "one", "sixteen", "thirty-two", "ten"] do
        # Similar "00000000-0000-0000-0000-000000000001" is unknown version for `Uniq`,
        # so we ignore test uuid in here.
        {:ok, uuid} = Typeid.uuid(typeid)
        assert UUID.to_string(uuid, :default) == unquote(item["uuid"])
      end
    end
  end
end
