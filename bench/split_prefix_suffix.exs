Benchee.run(
  %{
    "SplitBinary1" => fn -> SplitBinary1.split("user_01hyjwes2resp8jxqrrbt98jww") end,
    "SplitBinary2" => fn -> SplitBinary2.split("user_01hyjwes2resp8jxqrrbt98jww") end
  },
  print: [fast_warning: false],
  time: 10,
  memory_time: 2
)
