defmodule Typeid do
  @moduledoc """
  An Elixir implementation of [TypeID](https://github.com/jetify-com/typeid), and a formal
  [specification](https://github.com/jetify-com/typeid/tree/main/spec) defines the encoding
  in more detail.
  """

  defmodule Base32 do
    @moduledoc false
    use CrockfordBase32,
      bits_size: 130,
      alphabet: ~c"0123456789abcdefghjkmnpqrstvwxyz"
  end

  defstruct [:prefix, :suffix]

  alias Typeid.{Prefix, Suffix}

  @suffix_length 26
  @max_prefix_length 63
  @min_prefixed_typeid_length @suffix_length + 2
  @max_typeid_length @max_prefix_length + @suffix_length + 1

  @typedoc """
  A struct to describe a `Typeid`.
  """
  @type t :: %__MODULE__{
          prefix: String.t() | nil,
          suffix: String.t()
        }

  @doc """
  Generate a new `t:t/0` with the given type (as its prefix).

  Refer TypeID's specification, the given type can be a `nil` or an empty string `""`.

  ## Example
  
      iex> Typeid.new("user")
      {:ok, #Typeid<"user_01hzep1kb6ea1abhrg1zx021h8">}
      iex> Typeid.new(nil)
      {:ok, #Typeid<"01hzevjrxwf4b831t5vshyt571">}
      iex> Typeid.new("")
      {:ok, #Typeid<"01hzevjvc5fp0avt85w4z35wnw">}
  """
  @spec new(String.t() | nil) :: {:ok, t()} | :error
  def new(prefix) do
    if Prefix.valid?(prefix) do
      {:ok, %__MODULE__{prefix: prefix, suffix: Suffix.generate()}}
    else
      :error
    end
  end

  @doc """
  Transfer a `t:t/0` into a string.

  ## Example
  
      iex> {:ok, typeid} = Typeid.new("user")
      {:ok, #Typeid<"user_01hzep7s63fd5ted6f7wgqmx3m">}
      iex> Typeid.to_string(typeid)
      "user_01hzep7s63fd5ted6f7wgqmx3m"
  """
  @spec to_string(typeid :: t()) :: String.t()
  def to_string(%__MODULE__{prefix: p, suffix: s})
      when p == ""
      when p == nil do
    s
  end
  def to_string(%__MODULE__{prefix: p, suffix: s}) do
    "#{p}_#{s}"
  end

  @doc """
  Extract UUID data from the `t:t/0` using `Uniq.UUID`.

  `new/1` generates UUIDv7 suffixes. `parse/1` accepts every TypeID-valid payload,
  so this function returns `:error` when `Uniq.UUID` does not support the payload's UUID version.

  ## Example

      iex> {:ok, typeid} = Typeid.new("user")
      {:ok, #Typeid<"user_01hzep7s63fd5ted6f7wgqmx3m">}
      iex> Typeid.uuid(typeid)
      {:ok, #UUIDv7<018fdd63-e4c3-7b4b-a734-cf3f217a7474>}
  """
  @spec uuid(typeid :: t()) :: {:ok, Uniq.UUID.info()} | :error
  def uuid(%__MODULE__{suffix: s}) do
    Suffix.uuid(s)
  end

  @doc """
  Validate a `t:t/0` or a string TypeID format.

  ## Example
  
      iex> {:ok, typeid} = Typeid.new("user")
      {:ok, #Typeid<"user_01hzep7s63fd5ted6f7wgqmx3m">}
      iex> Typeid.valid?(typeid)
      true
      iex> Typeid.valid?("user_01hzep7s63fd5ted6f7wgqmx3m")
      true
      iex> Typeid.valid?("user_01hzep7s63fd5ted6f7wgqmx3")
      false
  """
  @spec valid?(typeid :: t()) :: boolean()
  @spec valid?(typeid :: String.t()) :: boolean()
  def valid?(%__MODULE__{prefix: prefix, suffix: suffix}) do
    valid_components?(prefix, suffix)
  end

  def valid?(typeid) when is_binary(typeid) do
    case split_typeid(typeid) do
      {prefix, suffix} -> valid_components?(prefix, suffix)
      :error -> false
    end
  end

  def valid?(_), do: false

  @doc """
  Parse a `t:t/0` from a string, if there is not given the prefix part of the Typeid, the `prefix` of the
  parsed `t:t/0` is processed as `nil`.

  ## Example
  
      iex> Typeid.parse("user_01hzep7s63fd5ted6f7wgqmx3m")
      {:ok, #Typeid<"user_01hzep7s63fd5ted6f7wgqmx3m">}
      iex> {:ok, typeid} = Typeid.parse("01hzep7s63fd5ted6f7wgqmx3m")
      {:ok, #Typeid<"01hzep7s63fd5ted6f7wgqmx3m">}
      iex> typeid.prefix
      nil

  """
  @spec parse(String.t()) :: {:ok, t()} | :error
  def parse(typeid) do
    case split_typeid(typeid) do
      {prefix, suffix} ->
        if valid_components?(prefix, suffix) do
          {:ok, %__MODULE__{prefix: prefix, suffix: suffix}}
        else
          :error
        end

      :error ->
        :error
    end
  end

  defp valid_components?(prefix, suffix) do
    Prefix.valid?(prefix) and Suffix.valid?(suffix)
  end

  defp split_typeid(<<suffix::binary-size(@suffix_length)>>), do: {nil, suffix}

  defp split_typeid(typeid)
       when is_binary(typeid) and byte_size(typeid) >= @min_prefixed_typeid_length and
              byte_size(typeid) <= @max_typeid_length do
    prefix_size = byte_size(typeid) - @suffix_length - 1

    case typeid do
      <<prefix::binary-size(prefix_size), ?_, suffix::binary-size(@suffix_length)>> ->
        {prefix, suffix}

      _ ->
        :error
    end
  end

  defp split_typeid(_), do: :error

  import Typeid.Macros, only: [defextension: 2]

  defextension Ecto.ParameterizedType do
    use Ecto.ParameterizedType

    @doc false
    @impl Ecto.ParameterizedType
    def type(_), do: :string

    @doc false
    @impl Ecto.ParameterizedType
    def init(opts) do
      type = Keyword.get(opts, :type)

      if Prefix.valid?(type) do
        %{type: type}
      else
        raise ArgumentError,
              "expected :type to be nil, \"\", or a valid TypeID prefix, got: #{inspect(type)}"
      end
    end

    @doc false
    @impl Ecto.ParameterizedType
    def cast(nil, _), do: {:ok, nil}

    def cast(%__MODULE__{} = typeid, %{type: type}) do
      serialize_typeid(typeid, type)
    end

    def cast(value, %{type: type}) when is_binary(value) do
      serialize_typeid(value, type)
    end

    def cast(_, _), do: :error

    @doc false
    @impl Ecto.ParameterizedType
    def autogenerate(%{type: type}) do
      %__MODULE__{prefix: type, suffix: Suffix.generate()}
    end

    @doc false
    @impl Ecto.ParameterizedType
    def load(nil, _, _), do: {:ok, nil}

    def load(value, _loader, %{type: type}) when is_binary(value) do
      serialize_typeid(value, type)
    end

    def load(_, _, _), do: :error

    @doc false
    @impl Ecto.ParameterizedType
    def dump(nil, _, _), do: {:ok, nil}

    def dump(%__MODULE__{} = typeid, _dumper, %{type: type}) do
      serialize_typeid(typeid, type)
    end

    def dump(value, _dumper, %{type: type}) when is_binary(value) do
      serialize_typeid(value, type)
    end

    def dump(_, _, _), do: :error

    defp serialize_typeid(%__MODULE__{prefix: prefix, suffix: suffix} = typeid, type) do
      if unprefixed_prefixes_match?(prefix, type) and valid_components?(prefix, suffix) do
        {:ok, Typeid.to_string(typeid)}
      else
        :error
      end
    end

    defp serialize_typeid(<<suffix::binary-size(@suffix_length)>> = value, type)
         when type == nil or type == "" do
      if Suffix.valid?(suffix), do: {:ok, value}, else: :error
    end

    defp serialize_typeid(value, type)
         when is_binary(value) and is_binary(type) and byte_size(type) > 0 do
      type_size = byte_size(type)

      case value do
        <<^type::binary-size(type_size), ?_, suffix::binary-size(@suffix_length)>> ->
          if Suffix.valid?(suffix), do: {:ok, value}, else: :error

        _ ->
          :error
      end
    end

    defp serialize_typeid(_, _), do: :error

    defp unprefixed_prefixes_match?(prefix, type)
         when prefix in [nil, ""] and type in [nil, ""], do: true

    defp unprefixed_prefixes_match?(prefix, type), do: prefix == type
  end

  defimpl String.Chars do
    def to_string(typeid), do: Typeid.to_string(typeid)
  end

  defimpl Inspect do
    import Inspect.Algebra

    def inspect(typeid, _opts) do
      concat(["#Typeid<\"", Typeid.to_string(typeid), "\">"])
    end
  end

  defextension Jason do
    defimpl Jason.Encoder do
      def encode(typeid, opts) do
        Jason.Encode.string(Typeid.to_string(typeid), opts)
      end
    end
  end
end
