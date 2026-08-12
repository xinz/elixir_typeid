defmodule TypeidTest do
  use ExUnit.Case

  test "new typeid" do
    {:ok, typeid} = Typeid.new("user")
    assert String.starts_with?(typeid.prefix, "user") == true
    assert String.starts_with?(typeid.prefix, "user_") == false
    assert String.length(typeid.suffix) == 26
  end

  test "new typeid with empty string or nil" do
    {:ok, typeid} = Typeid.new("")
    assert typeid.prefix == ""
    str = Typeid.to_string(typeid)
    assert String.starts_with?(str, "_") == false
    assert String.length(str) == 26

    {:ok, typeid} = Typeid.new(nil)
    assert typeid.prefix == nil
    str = Typeid.to_string(typeid)
    assert String.starts_with?(str, "_") == false
    assert String.length(str) == 26
  end

  test "new typeid with invalid type" do
    assert Typeid.new("123") == :error
    assert Typeid.new("User123") == :error
    assert Typeid.new("_user123") == :error
    assert Typeid.new("user123_") == :error
  end

  test "to_string" do
    {:ok, typeid} = Typeid.new("user")
    assert "user_#{typeid.suffix}" == Typeid.to_string(typeid)
  end

  test "extract uuid" do
    {:ok, typeid} = Typeid.new("user")
    {:ok, uuid} = Typeid.uuid(typeid)
    assert uuid.version == 7 and uuid.format == :raw
  end

  test "successfully parse string into typeid" do
    {:ok, typeid} = Typeid.new("user")
    assert {:ok, ^typeid} = Typeid.to_string(typeid) |> Typeid.parse()

    {:ok, typeid} = Typeid.parse("01hynkmr3genp92fjr9b74sqx4")
    assert typeid.prefix == nil and typeid.suffix == "01hynkmr3genp92fjr9b74sqx4"
    {:ok, typeid} = Typeid.parse("my_id_01hynkmr3genp92fjr9b74sqx4")
    assert typeid.prefix == "my_id" and typeid.suffix == "01hynkmr3genp92fjr9b74sqx4"
  end

  test "fail to parse string into typeid" do
    assert Typeid.parse("user") == :error
    assert Typeid.parse("user_12345") == :error
    assert Typeid.parse("_user_01hynks968e7fvj01pv8190s0y") == :error
    assert Typeid.parse("user1_01hynks968e7fvj01pv8190s0y") == :error
    assert Typeid.parse(" user_01hynks968e7fvj01pv8190s0y") == :error
    assert Typeid.parse("user__01hynks968e7fvj01pv8190s0y") == :error
    assert Typeid.parse("User_01hynks968e7fvj01pv8190s0y") == :error
    assert Typeid.parse("usEr_01hynks968e7fvj01pv8190s0y") == :error
    assert Typeid.parse("_00000000000000000000000000") == :error
  end

  test "parses and validates a maximum-length prefix" do
    prefix = String.duplicate("a", 63)
    suffix = "01hynkmr3genp92fjr9b74sqx4"
    value = "#{prefix}_#{suffix}"

    assert {:ok, %Typeid{prefix: ^prefix, suffix: ^suffix}} = Typeid.parse(value)
    assert Typeid.valid?(value)
    refute Typeid.valid?("#{prefix}a_#{suffix}")
  end

  test "check valid? with %Typeid{}" do
    assert Typeid.valid?(%Typeid{prefix: "user"}) == false
    assert Typeid.valid?(%Typeid{prefix: "user", suffix: "12345"}) == false
    assert Typeid.valid?(%Typeid{prefix: "_user", suffix: "01hynks968e7fvj01pv8190s0y"}) == false
    assert Typeid.valid?(%Typeid{prefix: "user1", suffix: "01hynks968e7fvj01pv8190s0y"}) == false
    assert Typeid.valid?(%Typeid{prefix: " user", suffix: "01hynks968e7fvj01pv8190s0y"}) == false
    assert Typeid.valid?(%Typeid{prefix: "user_", suffix: "01hynks968e7fvj01pv8190s0y"}) == false
    assert Typeid.valid?(%Typeid{prefix: "User", suffix: "01hynks968e7fvj01pv8190s0y"}) == false
    assert Typeid.valid?(%Typeid{prefix: "usEr", suffix: "01hynks968e7fvj01pv8190s0y"}) == false
    assert Typeid.valid?(%Typeid{prefix: "my_id", suffix: "01hynkmr3genp92fjr9b74sqx4"}) == true
    assert Typeid.valid?(%Typeid{prefix: "myid", suffix: "01hynkmr3genp92fjr9b74sqx4"}) == true
    assert Typeid.valid?(%Typeid{prefix: "", suffix: "01hynkmr3genp92fjr9b74sqx4"}) == true
    assert Typeid.valid?(%Typeid{prefix: nil, suffix: "01hynkmr3genp92fjr9b74sqx4"}) == true
  end

  test "check valid? with string" do
    assert Typeid.valid?("user") == false
    assert Typeid.valid?("user_12345") == false
    assert Typeid.valid?("_user_01hynks968e7fvj01pv8190s0y") == false
    assert Typeid.valid?("user1_01hynks968e7fvj01pv8190s0y") == false
    assert Typeid.valid?(" user_01hynks968e7fvj01pv8190s0y") == false
    assert Typeid.valid?("user__01hynks968e7fvj01pv8190s0y") == false
    assert Typeid.valid?("User_01hynks968e7fvj01pv8190s0y") == false
    assert Typeid.valid?("usEr_01hynks968e7fvj01pv8190s0y") == false
    assert Typeid.valid?("01hynkmr3genp92fjr9b74sqx4") == true
    assert Typeid.valid?("my_id_01hynkmr3genp92fjr9b74sqx4") == true
    assert Typeid.valid?("myid_01hynkmr3genp92fjr9b74sqx4") == true
  end

  if Code.ensure_loaded?(JSON.Encoder) do
    test "implements the built-in JSON encoder" do
      typeid = %Typeid{prefix: "user", suffix: "01hynkmr3genp92fjr9b74sqx4"}
      encoded_typeid = ~s("user_01hynkmr3genp92fjr9b74sqx4")

      assert JSON.encode!(typeid) == encoded_typeid
      assert JSON.encode!(%{id: typeid}) == ~s({"id":#{encoded_typeid}})
    end
  end

  test "implement jason encode" do
    {:ok, typeid} = Typeid.new("user")
    assert is_struct(typeid, Typeid) == true
    typeid_str = "#{typeid}"
    {:ok, content} = Jason.encode(%{"id" => typeid})
    assert String.contains?(content, typeid_str) == true

    devices = [
      %Typeid{prefix: "device", suffix: "00000000000000000000000001"},
      %Typeid{prefix: "device", suffix: "0000000000000000000000000a"},
      %Typeid{prefix: "device", suffix: "0000000000000000000000000g"}
    ]

    encoded = Jason.encode!(%{"devices" => devices})
    %{"devices" => encoded_devices} = Jason.decode!(encoded)
    input_order = Enum.map(devices, &Typeid.to_string/1)

    assert encoded_devices == input_order
    assert Enum.sort(encoded_devices) == input_order
  end
end
