# mix run before_after.exs
#
# The original implementation is copied from the parent of the optimization
# commit into `bench/lib/before/c9bfc3c`. Those modules retain the original runtime
# code and differ only by namespace, allowing both implementations to load in
# the same BEAM instance.

defmodule Typeid.Bench.BeforeAfter do
  alias Typeid.Bench.Before_c9bfc3c, as: Before
  alias Typeid.Bench.Before_c9bfc3c.Prefix, as: BeforePrefix
  alias Typeid.Bench.Before_c9bfc3c.Suffix, as: BeforeSuffix
  alias Typeid.{Prefix, Suffix}

  @baseline_revision "c9bfc3c"
  @valid_suffix "01hynkmr3genp92fjr9b74sqx4"
  @overflow_suffix "81hynkmr3genp92fjr9b74sqx4"
  @invalid_alphabet_suffix "01hynkmr3genp92fjr9b74sqxi"
  @max_prefix String.duplicate("a", 63)

  def run do
    assert_equivalent_results!()
    IO.puts("Baseline #{@baseline_revision} and current code agree on the complete benchmark corpus.\n")

    benchmark_suffix_validation()
    benchmark_suffix_generation()
    benchmark_prefix_validation()
    benchmark_parsing()
    benchmark_string_validation()
    benchmark_ecto_paths()
  end

  defp benchmark_suffix_validation do
    print_heading("Suffix validation")

    Benchee.run(
      %{
        "before: original Base32 decode" => &BeforeSuffix.valid?/1,
        "after: structural validation" => &Suffix.valid?/1
      },
      Keyword.merge(benchmark_options(), inputs: suffix_inputs())
    )
  end

  defp benchmark_suffix_generation do
    print_heading("Suffix generation")

    Benchee.run(
      %{
        "before: original encode then downcase" => &BeforeSuffix.generate/0,
        "after: lowercase encoder" => &Suffix.generate/0
      },
      benchmark_options()
    )
  end

  defp benchmark_prefix_validation do
    print_heading("Prefix validation")

    Benchee.run(
      %{
        "before: original generated clauses" => &BeforePrefix.valid?/1,
        "after: compact validator" => &Prefix.valid?/1
      },
      Keyword.merge(benchmark_options(), inputs: prefix_inputs())
    )
  end

  defp benchmark_parsing do
    print_heading("TypeID parsing")

    Benchee.run(
      %{
        "before: original binary_part split" => &Before.parse/1,
        "after: fixed-layout split" => &Typeid.parse/1
      },
      Keyword.merge(benchmark_options(), inputs: typeid_inputs())
    )
  end

  defp benchmark_string_validation do
    print_heading("String TypeID validation")

    Benchee.run(
      %{
        "before: original parse then discard struct" => &Before.valid?/1,
        "after: validate without struct" => &Typeid.valid?/1
      },
      Keyword.merge(benchmark_options(), inputs: typeid_inputs())
    )
  end

  defp benchmark_ecto_paths do
    if ecto_callbacks_available?() do
      before_params = Before.init(type: "user")
      current_params = Typeid.init(type: "user")
      input = {"user_#{@valid_suffix}", before_params, current_params}

      print_heading("Ecto cast")

      Benchee.run(
        %{
          "before: original String.replace_prefix" => fn {value, before_params, _} ->
            Before.cast(value, before_params)
          end,
          "after: exact binary match" => fn {value, _, current_params} ->
            Typeid.cast(value, current_params)
          end
        },
        Keyword.merge(benchmark_options(), inputs: %{"valid configured prefix" => input})
      )

      print_heading("Ecto load")

      Benchee.run(
        %{
          "before: original full TypeID parse" => fn {value, before_params, _} ->
            Before.load(value, nil, before_params)
          end,
          "after: exact binary match" => fn {value, _, current_params} ->
            Typeid.load(value, nil, current_params)
          end
        },
        Keyword.merge(benchmark_options(), inputs: %{"valid configured prefix" => input})
      )

      print_heading("Ecto autogenerate")

      Benchee.run(
        %{
          "before: original Typeid.new/1" => fn -> Before.autogenerate(before_params) end,
          "after: direct struct construction" => fn -> Typeid.autogenerate(current_params) end
        },
        benchmark_options()
      )
    else
      IO.puts("Skipping Ecto benchmarks: callbacks are not available in both implementations.\n")
    end
  end

  defp assert_equivalent_results! do
    assert_equivalent!(
      "suffix validation",
      suffix_inputs(),
      &BeforeSuffix.valid?/1,
      &Suffix.valid?/1
    )

    assert_equivalent!(
      "prefix validation",
      prefix_inputs(),
      &BeforePrefix.valid?/1,
      &Prefix.valid?/1
    )

    assert_equivalent!(
      "TypeID parsing",
      typeid_inputs(),
      &Before.parse/1,
      &Typeid.parse/1,
      &normalize_parse_result/1
    )

    assert_equivalent!(
      "string TypeID validation",
      typeid_inputs(),
      &Before.valid?/1,
      &Typeid.valid?/1
    )

    if ecto_callbacks_available?() do
      before_params = Before.init(type: "user")
      current_params = Typeid.init(type: "user")
      inputs = %{"valid configured prefix" => {"user_#{@valid_suffix}", before_params, current_params}}

      assert_equivalent!(
        "Ecto cast",
        inputs,
        fn {value, before_params, _} -> Before.cast(value, before_params) end,
        fn {value, _, current_params} -> Typeid.cast(value, current_params) end
      )

      assert_equivalent!(
        "Ecto load",
        inputs,
        fn {value, before_params, _} -> Before.load(value, nil, before_params) end,
        fn {value, _, current_params} -> Typeid.load(value, nil, current_params) end
      )

      assert_autogenerate_contract!(before_params, current_params)
    end
  end

  defp assert_equivalent!(name, inputs, before, current) do
    assert_equivalent!(name, inputs, before, current, fn value -> value end)
  end

  defp assert_equivalent!(name, inputs, before, current, normalize) do
    Enum.each(inputs, fn {input_name, input} ->
      before_result = normalize.(before.(input))
      current_result = normalize.(current.(input))

      if before_result != current_result do
        raise "#{name} differs for #{inspect(input_name)}: " <>
                "before=#{inspect(before_result)}, after=#{inspect(current_result)}"
      end
    end)
  end

  # The namespace is deliberately different for the copied baseline struct.
  # Compare parse results by their public data instead of their struct module.
  defp normalize_parse_result({:ok, %{prefix: prefix, suffix: suffix}}), do: {:ok, {prefix, suffix}}
  defp normalize_parse_result(result), do: result

  # Generated UUIDv7 payloads are intentionally random, so equality is not a
  # useful assertion. Verify equivalent output contracts before benchmarking.
  defp assert_autogenerate_contract!(before_params, current_params) do
    before_typeid = Before.autogenerate(before_params)
    current_typeid = Typeid.autogenerate(current_params)

    valid? = fn %{prefix: prefix, suffix: suffix} ->
      prefix == "user" and BeforePrefix.valid?(prefix) and BeforeSuffix.valid?(suffix) and
        Prefix.valid?(prefix) and Suffix.valid?(suffix)
    end

    unless valid?.(before_typeid) and valid?.(current_typeid) do
      raise "Ecto autogenerate contract differs between the baseline and current implementation"
    end
  end

  defp suffix_inputs do
    %{
      "valid" => @valid_suffix,
      "invalid first character" => @overflow_suffix,
      "invalid alphabet character" => @invalid_alphabet_suffix
    }
  end

  defp prefix_inputs do
    %{
      "empty" => "",
      "short valid" => "user",
      "max valid" => @max_prefix,
      "invalid leading underscore" => "_user",
      "invalid trailing underscore" => String.duplicate("a", 62) <> "_",
      "overlength" => String.duplicate("a", 64)
    }
  end

  defp typeid_inputs do
    %{
      "bare suffix" => @valid_suffix,
      "short prefix" => "user_#{@valid_suffix}",
      "max prefix" => "#{@max_prefix}_#{@valid_suffix}",
      "invalid suffix overflow" => "user_#{@overflow_suffix}",
      "invalid suffix alphabet" => "user_#{@invalid_alphabet_suffix}",
      "invalid separator" => "user-#{@valid_suffix}"
    }
  end

  defp benchmark_options do
    [
      print: [fast_warning: false],
      warmup: duration_from_environment("BENCH_WARMUP", 1),
      time: duration_from_environment("BENCH_TIME", 2),
      memory_time: duration_from_environment("BENCH_MEMORY_TIME", 1)
    ]
  end


  defp duration_from_environment(name, default) do
    case System.get_env(name) do
      nil -> default

      value ->
        case Integer.parse(value) do
          {duration, ""} when duration >= 0 -> duration
          _ -> raise ArgumentError, "#{name} must be a non-negative integer, got: #{inspect(value)}"
        end
    end
  end

  defp ecto_callbacks_available? do
    Code.ensure_loaded?(Ecto.ParameterizedType) and
      Enum.all?(
        [
          {Before, :init, 1},
          {Before, :cast, 2},
          {Before, :load, 3},
          {Before, :autogenerate, 1},
          {Typeid, :init, 1},
          {Typeid, :cast, 2},
          {Typeid, :load, 3},
          {Typeid, :autogenerate, 1}
        ],
        fn {module, function, arity} -> function_exported?(module, function, arity) end
      )
  end

  defp print_heading(name) do
    IO.puts("\n== #{name} ==")
  end
end

Typeid.Bench.BeforeAfter.run()
