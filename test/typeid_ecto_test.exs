defmodule Typeid.Ecto.Test do
  use ExUnit.Case, async: true

  alias Ecto.TestRepo

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

end
