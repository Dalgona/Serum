defmodule Serum.V2.Console do
  @moduledoc """
  A `GenServer` process which centralizes message outputs in Serum.

  By using `Serum.V2.Console`, you can have your plugins or themes print messages
  in a pretty and consistent format.

  ## Testing your code which uses `Serum.V2.Console`

  The `Serum.V2.Console` process is automatically started when Serum starts. So
  you don't need to start the process in your plugins or themes. However, when
  you are running ExUnit tests for your codes, you may have to manually start
  process by adding the following line to your `test/test_helper.exs`:

  ```
  {:ok, _pid} = Serum.V2.Console.start_link([])
  ```
  """

  use GenServer
  alias Serum.V2.Result

  message_categories = [
    debug: {[:light_black_background, :black], [:light_black]},
    error: {[:red_background, :light_white], [:light_white]},
    gen: {[:light_green], []},
    info: {[:light_black_background, :white], []},
    mkdir: {[:light_cyan], []},
    plugin: {[:light_magenta], []},
    read: {[:light_yellow], []},
    theme: {[:light_magenta], []},
    warn: {[:yellow_background, :black], [:yellow]}
  ]

  @type config :: %{mute_msg: boolean(), mute_err: boolean()}

  @spec start_link(term()) :: GenServer.on_start()
  def start_link(_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc "Gets the current configuration of `Serum.Console`."
  @spec config() :: Result.t(config())
  def config do
    GenServer.call(__MODULE__, :get_config)
  end

  @doc """
  Configures `Serum.Console`.

  ## Options

  - `mute_err` (boolean): Controls whether outputs to `:stderr` must be
    suppressed. Defaults to `false`.
  - `mute_msg` (boolean): Controls whether outputs to `:stdio` must be
    suppressed. Defaults to `false`.
  """
  @spec config(keyword()) :: Result.t({})
  def config(options) when is_list(options) do
    GenServer.call(__MODULE__, {:set_config, options})
  end

  @doc """
  Prints a message to the standard output.

  Available categories are:
  `#{message_categories |> Keyword.keys() |> inspect()}`
  """
  @spec put_msg(atom(), IO.ANSI.ansidata()) :: Result.t({})
  def put_msg(category, msg) do
    GenServer.call(__MODULE__, {:put_msg, category, msg})
  end

  @doc """
  Prints a message to the standard error output.

  Available categories are:
  `#{message_categories |> Keyword.keys() |> inspect()}`
  """
  @spec put_err(atom(), IO.ANSI.ansidata()) :: Result.t({})
  def put_err(category, msg) do
    GenServer.call(__MODULE__, {:put_err, category, msg})
  end

  @impl GenServer
  def init(_args) do
    prefix = if IO.ANSI.enabled?(), do: "\r", else: ""

    {:ok, %{mute_msg: false, mute_err: false, prefix: prefix}}
  end

  @impl GenServer
  def handle_call(request, from, state)
  def handle_call(:get_config, _, state), do: {:reply, {:ok, state}, state}

  def handle_call({:set_config, conf}, _, state) do
    conf_map = conf |> Map.new() |> Map.take([:mute_msg, :mute_err])

    {:reply, {:ok, {}}, Map.merge(state, conf_map)}
  end

  def handle_call({:put_msg, category, msg}, _, state) do
    unless state.mute_msg do
      IO.puts([state.prefix, format_message(category, msg)])
    end

    {:reply, {:ok, {}}, state}
  end

  def handle_call({:put_err, category, msg}, _, state) do
    unless state.mute_err do
      IO.puts(:stderr, [state.prefix, format_message(category, msg)])
    end

    {:reply, {:ok, {}}, state}
  end

  max_length =
    message_categories
    |> Enum.map(fn {category, _} -> to_string(category) end)
    |> Enum.map(&String.length/1)
    |> Enum.max()

  @spec format_message(atom(), IO.ANSI.ansidata()) :: IO.chardata()
  defp format_message(category, msg)

  Enum.each(message_categories, fn {category, {head_style, body_style}} ->
    cat_str = category |> to_string() |> String.upcase()
    header = [head_style, String.pad_leading(cat_str, max_length + 1), ?\s]
    body_fmt = [body_style, "~ts"]

    defp format_message(unquote(category), msg) do
      header = unquote(header) |> IO.ANSI.format() |> IO.iodata_to_binary()
      body_fmt = unquote(body_fmt) |> IO.ANSI.format() |> IO.iodata_to_binary()

      formatted_msg =
        msg
        |> IO.ANSI.format()
        |> IO.iodata_to_binary()
        |> format_newlines()

      [header, ?\s, :io_lib.format(body_fmt, [formatted_msg])]
    end
  end)

  @spec format_newlines(binary()) :: IO.chardata()
  defp format_newlines(msg) do
    lines = String.split(msg, ~r/\r?\n/)
    indent = String.duplicate(" ", unquote(max_length) + 3)

    Enum.intersperse(lines, ["\n", indent])
  end
end
