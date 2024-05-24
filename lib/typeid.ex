defmodule Typeid do

  defmodule Base32 do
    @moduledoc false
    use CrockfordBase32,
      bits_size: 130
  end

  defstruct [:prefix, :suffix]

  alias Typeid.{Prefix, Suffix}

  @type info :: %__MODULE__{
          prefix: String.t(),
          suffix: String.t()
        }

  @spec new(String.t()) :: {:ok, info} | :error
  def new(type) when type == "" or type == nil do
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

  @spec to_string(typeid :: info) :: String.t()
  def to_string(%__MODULE__{prefix: p, suffix: s}) when p == "" or p == nil do
    s
  end
  def to_string(%__MODULE__{prefix: p, suffix: s}) do
    "#{p}_#{s}"
  end

  @spec uuid(typeid :: info) :: {:ok, Uniq.UUID.info()} | :error
  def uuid(%__MODULE__{suffix: s}) do
    Suffix.uuid(s)
  end

  @spec parse(String.t()) :: {:ok, info} | :error
  def parse(string) when byte_size(string) > 27 do 
    size = byte_size(string)
    prefix = binary_part(string, 0, size-27)
    underscore_suffix = binary_part(string, size - 27, 27)

    with {prefix, suffix} = match(prefix, underscore_suffix),
         true <- Prefix.valid?(prefix) and Suffix.valid?(suffix) do
      {:ok, %__MODULE__{prefix: prefix, suffix: suffix}}
    else
      _ -> :error
    end
  end
  def parse(<<_::binary-size(26)>> = string) do
    if Suffix.valid?(string) do
      {:ok, %__MODULE__{prefix: "", suffix: string}}
    else
      :error
    end
  end

  def parse(_), do: :error

  defp match(prefix, <<"_"::binary, suffix::binary>>) do
    {prefix, suffix}
  end
  defp match(_, _), do: :error
end


defimpl Inspect, for: Typeid do
  import Inspect.Algebra

  def inspect(typeid, _opts) do
    concat(["#Typeid<\"", Typeid.to_string(typeid), "\">"])
  end
end
