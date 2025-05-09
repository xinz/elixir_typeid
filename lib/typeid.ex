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


  @typedoc """
  A struct to describe a `TypeID`. 
  """
  @type t :: %__MODULE__{
          prefix: String.t(),
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
  @spec new(String.t()) :: {:ok, t()} | :error
  def new(type)
      when type == ""
      when type == nil do
    {:ok, %__MODULE__{prefix: type, suffix: Suffix.generate()}}
  end
  def new(type) do
    with true <- Prefix.valid?(type),
         suffix when is_binary(suffix) <- Suffix.generate() do
      {:ok, %__MODULE__{prefix: type, suffix: suffix}}
    else
      _ ->
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
  Extract the UUIDv7 from the `t:t/0`, the return UUIDv7 struct depends `Uniq.UUID`.

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
    Prefix.valid?(prefix) and Suffix.valid?(suffix)
  end
  def valid?(typeid) do
    case parse(typeid) do
      {:ok, _} ->
        true
      _ ->
        false
    end
  end

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
  def parse(string) when byte_size(string) > 27 do 
    size = byte_size(string)
    prefix = binary_part(string, 0, size - 27)
    underscore_suffix = binary_part(string, size - 27, 27)

    with {prefix, suffix} <- check_prefix_underscore_suffix(prefix, underscore_suffix),
         true <- Prefix.valid?(prefix) and Suffix.valid?(suffix) do
      {:ok, %__MODULE__{prefix: prefix, suffix: suffix}}
    else
      _error ->
        :error
    end
  end
  def parse(<<_::binary-size(26)>> = string) do
    if Suffix.valid?(string) do
      {:ok, %__MODULE__{prefix: nil, suffix: string}}
    else
      :error
    end
  end
  def parse(_), do: :error

  defp check_prefix_underscore_suffix(prefix, <<"_"::binary, suffix::binary>>) do
    {prefix, suffix}
  end
  defp check_prefix_underscore_suffix(_, _), do: :error

  import Typeid.Macros, only: [defextension: 2]

  defextension Ecto.ParameterizedType do
    use Ecto.ParameterizedType

    @doc false
    @impl Ecto.ParameterizedType
    def type(_), do: :string

    @doc false
    @impl Ecto.ParameterizedType
    def init(opts) do
      type = opts[:type]
      %{type: type}
    end

    @doc false
    @impl Ecto.ParameterizedType
    def cast(nil, _), do: {:ok, nil}
    def cast(value, %{type: type}) when byte_size(value) > 27 do
      suffix = String.replace_prefix(value, "#{type}_", "")
      if Suffix.valid?(suffix) do
        {:ok, value}
      else
        :error
      end
    end
    def cast(value, %{type: type})
        when type == nil and byte_size(value) == 26
        when type == "" and byte_size(value) == 26 do
      if Suffix.valid?(value) do
        {:ok, value}
      else
        :error
      end
    end
    def cast(%__MODULE__{} = typeid, %{type: type}) do
      if typeid.prefix == type do
        {:ok, Typeid.to_string(typeid)}
      else
        :error
      end
    end
    def cast(_, _), do: :error

    @doc false
    @impl Ecto.ParameterizedType
    def autogenerate(%{type: type}) do
      {:ok, typeid} = Typeid.new(type)
      typeid
    end

    @doc false
    @impl Ecto.ParameterizedType
    def load(nil, _, _), do: {:ok, nil}
    def load(value, _loader, %{type: type}) when byte_size(value) > 27 do
      case Typeid.parse(value) do
        {:ok, %__MODULE__{prefix: ^type}} ->
          {:ok, value}
        _ ->
          :error
      end
    end
    def load(value, _loader, %{type: type})
        when type == nil and byte_size(value) == 26
        when type == "" and byte_size(value) == 26 do
      if Typeid.Suffix.valid?(value) do
        {:ok, value}
      else
        :error
      end
    end
    def load(_, _, _), do: :error

    @doc false
    @impl Ecto.ParameterizedType
    def dump(nil, _, _), do: {:ok, nil}
    def dump(%__MODULE__{} = typeid, _dumper, %{type: type})
        when type == ""
        when type == nil do
      {:ok, Typeid.to_string(typeid)}
    end
    def dump(%__MODULE__{} = typeid, _dumper, %{type: type}) do
      if typeid.prefix == type do
        {:ok, Typeid.to_string(typeid)}
      else
        :error
      end
    end
    def dump(typeid, _dumper, %{type: type})
        when is_binary(typeid) and type == nil
        when is_binary(typeid) and type == "" do
      if Suffix.valid?(typeid) do
        {:ok, typeid}
      else
        :error
      end
    end
    def dump(typeid, _dumper, %{type: type}) when is_binary(typeid) do
      if String.starts_with?(typeid, type) do
        {:ok, typeid}
      else
        :error
      end
    end
    def dump(_, _, _), do: :error
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
