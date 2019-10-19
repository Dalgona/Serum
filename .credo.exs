%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ~w(lib/ test/)
      },
      checks: [
        {Credo.Check.Refactor.MapInto, false},
        {Credo.Check.Warning.LazyLogging, false}
      ]
    }
  ]
}
