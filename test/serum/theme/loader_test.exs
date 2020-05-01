defmodule Serum.Theme.LoaderTest do
  use Serum.Case
  require Serum.V2.Result, as: Result
  alias Serum.Theme
  alias Serum.Theme.Loader
  alias Serum.V2.Error

  setup(do: on_exit(fn -> Agent.update(Theme, fn _ -> {nil, nil} end) end))

  describe "load_theme/1" do
    test "loads a theme when a theme module name is given" do
      theme_mock = get_theme_mock()

      expected = %Theme{
        module: theme_mock,
        name: "",
        description: "",
        version: Version.parse!("0.1.0"),
        args: nil
      }

      assert {:ok, expected} == Loader.load_theme(theme_mock)
      assert {^expected, nil} = Agent.get(Theme, & &1)
    end

    test "loads a theme when a theme spec is given" do
      theme_mock = get_theme_mock(%{init: fn arg -> {:ok, arg} end})

      assert {:ok, %Theme{}} = Loader.load_theme({theme_mock, args: "hello"})
      assert {%Theme{}, "hello"} = Agent.get(Theme, & &1)
    end

    test "returns nil if nil is given" do
      assert {:ok, nil} === Loader.load_theme(nil)
      assert {nil, nil} === Agent.get(Theme, & &1)
    end

    test "returns an error if theme option is invalid" do
      theme_mock = get_theme_mock()

      assert {:error, %Error{}} = Loader.load_theme({theme_mock, [:foo]})
    end

    test "returns an error if an invalid theme spec is given" do
      assert {:error, %Error{}} = Loader.load_theme(:foo)

      # Must use `nil` not to load any theme.
      assert {:error, %Error{}} = Loader.load_theme({nil, []})
    end

    test "returns an error if name/0 callback raises" do
      theme_mock = get_theme_mock(%{name: fn -> raise "test: name" end})
      {:error, %Error{} = error} = Loader.load_theme(theme_mock)
      message = to_string(error)

      assert message =~ "RuntimeError"
      assert message =~ "test: name"
    end

    test "returns an error if init/0 callback returns an error" do
      theme_mock = get_theme_mock(%{init: fn _ -> Result.fail(Simple: ["test: init"]) end})
      {:error, %Error{} = error} = Loader.load_theme(theme_mock)
      message = to_string(error)

      assert message =~ "Serum.V2.Theme.Mock.init"
      assert message =~ "test: init"
    end

    test "returns an error if init/0 callback raises" do
      theme_mock = get_theme_mock(%{init: fn _ -> raise "test: init" end})
      {:error, %Error{} = error} = Loader.load_theme(theme_mock)
      message = to_string(error)

      assert message =~ "RuntimeError"
      assert message =~ "test: init"
    end
  end
end
