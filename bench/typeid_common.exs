
Benchee.run(
  %{
    "typeid_elixir parse from string and validate within only suffix" => fn -> TypeID.from_string("01hyhy1t0yfrcryhwr59pgh8rw") end,
    "typeid(me) parse from string and validate within only suffix" => fn -> Typeid.parse("01hyhy1t0yfrcryhwr59pgh8rw") end
  },
  print: [fast_warning: false],
  time: 10,
  memory_time: 2
)

Benchee.run(
  %{
    "typeid_elixir parse from string and validate within small prefix" => fn -> TypeID.from_string("user_01hyhy1t0yfrcryhwr59pgh8rw") end,
    "typeid(me) parse from string and validate within small prefix" => fn -> Typeid.parse("user_01hyhy1t0yfrcryhwr59pgh8rw") end
  },
  print: [fast_warning: false],
  time: 10,
  memory_time: 2
)


Benchee.run(
  %{
    "typeid_elixir parse from string and validate within max prefix" => fn -> TypeID.from_string("userabcdefghijklmnoprtuserabcdefghijklmnoprtuserabcdefghijklmno_01hyhy1t0yfrcryhwr59pgh8rw") end,
    "typeid(me) parse from string and validate within max prefix" => fn -> Typeid.parse("userabcdefghijklmnoprtuserabcdefghijklmnoprtuserabcdefghijklmno_01hyhy1t0yfrcryhwr59pgh8rw") end,
  },
  print: [fast_warning: false],
  time: 10,
  memory_time: 2
)

