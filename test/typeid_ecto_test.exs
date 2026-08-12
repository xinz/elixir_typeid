defmodule Typeid.Ecto.Test do
  use ExUnit.Case, async: true

  alias Ecto.TestRepo

  @suffix "01hynkmr3genp92fjr9b74sqx4"

  defmodule Person1 do
    use Ecto.Schema

    @primary_key {:id, Typeid, autogenerate: true, type: "person_a"}
    schema "person" do
      field(:name, :string)
    end
  end

  defmodule Person2 do
    use Ecto.Schema

    @primary_key false
    schema "person" do
      field(:key, Typeid, autogenerate: true, primary_key: true, type: "person_b")
      field(:name, :string)
    end
  end

  defmodule Person3 do
    use Ecto.Schema

    @primary_key false
    schema "person" do
      field(:id, Typeid, autogenerate: true, primary_key: true)
      field(:name, :string)
      field(:age, :integer)
    end
  end

  test "autogenerate primary key" do
    %Person1{id: id} = Ecto.Changeset.cast(%Person1{}, %{name: "Sun"}, [:name]) |> TestRepo.insert!()
    assert is_struct(id, Typeid) == true
    assert id.prefix == "person_a" and String.length(id.suffix) == 26

    %Person2{key: key} = Ecto.Changeset.cast(%Person2{}, %{name: "Sun"}, [:name]) |> TestRepo.insert!()
    assert is_struct(key, Typeid) == true
    assert key.prefix == "person_b" and String.length(key.suffix) == 26

    %Person3{id: id} = Ecto.Changeset.cast(%Person3{}, %{name: "Sun", age: 22}, [:name, :age]) |> TestRepo.insert!()
    assert is_struct(id, Typeid) == true
    assert id.prefix == nil and String.length(id.suffix) == 26
  end

  test "query by primary key" do
    {:ok, typeid} = Typeid.new("person_a")
    typeid_str = Typeid.to_string(typeid)
    assert %Person1{id: ^typeid_str} = TestRepo.load(Person1, %{id: typeid_str})

    name = "Sun"
    Process.put(:test_repo_all_results, {1, [[typeid_str, name]]})

    assert %Person1{id: ^typeid_str, name: ^name} = TestRepo.get(Person1, typeid_str)
    assert %Person1{id: ^typeid_str, name: ^name} = TestRepo.get(Person1, typeid)
    assert %Person1{id: ^typeid_str, name: ^name} = TestRepo.get_by(Person1, id: typeid_str)
    assert %Person1{id: ^typeid_str, name: ^name} = TestRepo.get_by(Person1, id: typeid)

    {:ok, typeid} = Typeid.new(nil)
    typeid_str = Typeid.to_string(typeid)
    assert String.length(typeid_str) == 26
    assert %Person3{id: ^typeid_str} = TestRepo.load(Person3, %{id: typeid_str})
    name = "Q"
    age = 22
    Process.put(:test_repo_all_results, {1, [[typeid_str, name, age]]})
    assert %Person3{id: ^typeid_str, name: ^name, age: ^age} = TestRepo.get(Person3, typeid_str)
    assert %Person3{id: ^typeid_str, name: ^name, age: ^age} = TestRepo.get(Person3, typeid)
    assert %Person3{id: ^typeid_str, name: ^name, age: ^age} = TestRepo.get_by(Person3, id: typeid_str)
    assert %Person3{id: ^typeid_str, name: ^name, age: ^age} = TestRepo.get_by(Person3, id: typeid)
  end

  test "validates TypeIDs and configured prefixes at Ecto boundaries" do
    params = Typeid.init(type: "person_a")
    bare_params = Typeid.init([])
    value = "person_a_#{@suffix}"
    collision = "person_ax_#{@suffix}"
    invalid_suffix = "person_a_bad"
    invalid_struct = %Typeid{prefix: "person_a", suffix: "bad"}
    wrong_prefix_struct = %Typeid{prefix: "person_b", suffix: @suffix}

    assert {:ok, ^value} = Typeid.cast(value, params)
    assert {:ok, ^value} = Typeid.load(value, nil, params)
    assert {:ok, ^value} = Typeid.dump(value, nil, params)
    assert {:ok, ^value} = Typeid.cast(%Typeid{prefix: "person_a", suffix: @suffix}, params)

    for invalid <- [collision, invalid_suffix, invalid_struct, wrong_prefix_struct] do
      assert :error = Typeid.cast(invalid, params)
      assert :error = Typeid.load(invalid, nil, params)
      assert :error = Typeid.dump(invalid, nil, params)
    end

    assert {:ok, @suffix} = Typeid.cast(@suffix, bare_params)

    for type <- [nil, ""], prefix <- [nil, ""] do
      params = Typeid.init(type: type)
      typeid = %Typeid{prefix: prefix, suffix: @suffix}

      assert {:ok, @suffix} = Typeid.cast(typeid, params)
      assert {:ok, @suffix} = Typeid.dump(typeid, nil, params)
    end

    assert :error = Typeid.dump(value, nil, bare_params)
    assert :error = Typeid.dump(%Typeid{prefix: "person_a", suffix: @suffix}, nil, bare_params)
  end

  test "rejects invalid Ecto type options" do
    assert %{type: "person_a"} = Typeid.init(type: "person_a")
    assert %{type: nil} = Typeid.init([])
    assert %{type: ""} = Typeid.init(type: "")

    assert_raise ArgumentError, ~r/valid TypeID prefix/, fn ->
      Typeid.init(type: "Person")
    end
  end
end
