defmodule IntegrateSpecTest do
  use ExUnit.Case
  alias Typeid.Test.JSONReader
  alias Uniq.UUID

  for item <- JSONReader.invalid_cases() do
    test "spec invalid - #{item["description"]}" do
      assert :error == Typeid.parse(unquote(item["typeid"]))
    end
  end

  for item <- JSONReader.valid_cases() do
    test "spec valid - #{item["name"]} - #{item["prefix"]}" do
      assert {:ok, typeid} = Typeid.parse(unquote(item["typeid"]))
      assert typeid.prefix == unquote(item["prefix"])
      if unquote(item["name"]) not in ["max-valid", "one", "sixteen", "thirty-two", "ten"] do
        # Similar "00000000-0000-0000-0000-000000000001" is unknown version for `Uniq`,
        # so we ignore test uuid in here.
        {:ok, uuid} = Typeid.uuid(typeid)
        assert UUID.to_string(uuid, :default) == unquote(item["uuid"])
      end
    end
  end
end
