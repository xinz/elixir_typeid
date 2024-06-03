# Typeid

An Elixir implementation of [TypeID](https://github.com/jetify-com/typeid).

TypeIDs are a modern, type-safe, globally unique identifier based on the upcoming
UUIDv7 standard. They provide a ton of nice properties that make them a great choice
as the primary identifiers for your data in a database, APIs, and distributed systems.
Read more about TypeIDs in the [specification](https://github.com/jetify-com/typeid/tree/main/spec).

## Installation

```elixir
def deps do
  [
    {:elixir_typeid, "~> 0.1"}
  ]
end
```

## Intro

- The [test cases](https://github.com/jetify-com/typeid/tree/main/spec#validating-implementations) of the formal specification are 100% covered.
- Implements `Ecto.ParameterizedType` can optionally integrate with Ecto schema.
- Implements `Jason.Encoder` can optionally inegerate with `jason` encoding.

## Usage

```elixir
iex> {:ok, typeid} = Typeid.new("user")
{:ok, #Typeid<"user_01hz6wxrw2ecmtwaqhnnpr275f">}
iex> "#{typeid}"
"user_01hz6wxrw2ecmtwaqhnnpr275f"
iex> Typeid.uuid(typeid)
{:ok, #UUIDv7<018fcdce-e382-7329-ae2a-f1ad6d811caf>}
iex> Typeid.parse("user_01hz6wxrw2ecmtwaqhnnpr275f")
{:ok, #Typeid<"user_01hz6wxrw2ecmtwaqhnnpr275f">}
iex> Typeid.valid?(typeid)
true
```

### Use with Ecto

In usual we use TypeID to generate the primary key with Ecto schema, define `Typeid` type within `@primary_key`:

```elixir

  defmodule User do
    use Ecto.Schema

    @primary_key {:id, Typeid, autogenerate: true, type: "user"}
    schema "user" do
      field(:name, :string)
    end
  end

```

or define `Typeid` type in a primary key field of a schema:

```elixir

  defmodule User do
    use Ecto.Schema

    @primary_key false
    schema "user" do
      field(:user_id, Typeid, autogenerate: true, primary_key: true, type: "user")
      field(:name, :string)
    end
  end
```

If the `type: "user"` in the above mentioned examples is not set, there will process the prefix of the Typeid as `nil`.

### Use with Jason Encoding

We can simply encode `Typeid` struct within Jason.

```elixir
iex> typeid
#Typeid<"user_01hz6wxrw2ecmtwaqhnnpr275f">
iex> Jason.encode(%{id: typeid})
{:ok, "{\"id\":\"user_01hz6wxrw2ecmtwaqhnnpr275f\"}"}
```
