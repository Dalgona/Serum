defmodule Serum.ThemeTest do
  use Serum.Case
  alias Serum.Theme
  alias Serum.V2.Console

  setup_all do
    {:ok, console_config} = Console.config()

    Console.config(mute_err: false, mute_msg: false)
    on_exit(fn -> Console.config(Keyword.new(console_config)) end)
  end

  setup do: on_exit(fn -> Agent.update(Theme, fn _ -> {nil, nil} end) end)

  describe "show_info/1" do
    test "prints information about the given theme" do
      theme_mock =
        get_theme_mock(%{
          name: fn -> "Test Theme" end,
          description: fn -> "This is a test theme." end,
          version: fn -> "1.2.3" end
        })

      {:ok, %Theme{} = theme} = Theme.load(theme_mock)
      console = Process.whereis(Console)
      original_gl = Process.info(console)[:group_leader]
      {:ok, string_io} = StringIO.open("")

      Process.group_leader(console, string_io)
      Theme.show_info(theme)
      Process.group_leader(console, original_gl)

      {:ok, {_, output}} = StringIO.close(string_io)

      [
        "Test Theme",
        "v1.2.3",
        "This is a test theme",
        "Serum.V2.Theme.Mock"
      ]
      |> Enum.each(&assert output =~ &1)
    end

    test "prints nothing if the argument is nil" do
      console = Process.whereis(Console)
      original_gl = Process.info(console)[:group_leader]
      {:ok, string_io} = StringIO.open("")

      Process.group_leader(console, string_io)
      Theme.show_info(nil)
      Process.group_leader(console, original_gl)

      assert {:ok, {"", ""}} === StringIO.close(string_io)
    end
  end
end
