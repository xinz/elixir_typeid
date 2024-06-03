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
    assert typeid.prefix == "" and typeid.suffix == "01hynkmr3genp92fjr9b74sqx4"
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

  test "check valid?" do
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
  end

  test "implement jason encode" do
    {:ok, typeid} = Typeid.new("user")
    assert is_struct(typeid, Typeid) == true
    typeid_str = "#{typeid}"
    {:ok, content} = Jason.encode(%{"id" => typeid})
    assert String.contains?(content, typeid_str) == true

    {:ok, t1} = Typeid.new("device")
    Process.sleep(100)
    {:ok, t2} = Typeid.new("device")
    Process.sleep(100)
    {:ok, t3} = Typeid.new("device")
    encoded = Jason.encode!(%{"devices" => [t1, t2, t3]})
    %{"devices" => devices} = Jason.decode!(encoded)
    input_order = ["#{t1}", "#{t2}", "#{t3}"]
    assert devices == input_order
    # Sorts items according to the generated time-ordered in ascending
    assert Enum.sort(devices) == input_order
  end
end
