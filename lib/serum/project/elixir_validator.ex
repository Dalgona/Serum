defmodule Serum.Project.ElixirValidator do
  @moduledoc false

  _moduledocp = "A module for validation of Serum project definition data."

  @type result() :: :ok | {:invalid, binary()} | {:invalid, [binary()]}

  @all_keys [
    :site_name,
    :site_description,
    :author,
    :author_email,
    :server_root,
    :base_url,
    :date_format,
    :list_title_all,
    :list_title_tag,
    :pagination,
    :posts_per_page,
    :preview_length,
    :posts_source,
    :posts_path,
    :tags_path,
    :plugins,
    :theme
  ]

  @required_keys [
    :site_name,
    :site_description,
    :author,
    :author_email,
    :base_url
  ]

  @spec validate(map()) :: result()
  def validate(term)

  def validate(%{} = map) do
    keys = map |> Map.keys() |> MapSet.new()

    with {:missing, []} <- check_missing_keys(keys),
         {:extra, []} <- check_extra_keys(keys),
         :ok <- check_constraints(map) do
      :ok
    else
      {:missing, [x]} ->
        {:invalid, "missing required property: #{x}"}

      {:missing, xs} ->
        props_str = Enum.join(xs, ", ")

        {:invalid, "missing required properties: #{props_str}"}

      {:extra, [x]} ->
        {:invalid, "unknown property: #{x}"}

      {:extra, xs} ->
        props_str = Enum.join(xs, ", ")

        {:invalid, "unknown properties: #{props_str}"}

      {:error, messages} ->
        {:invalid, messages}
    end
  end

  def validate(term) do
    {:invalid, "expected a map, got: #{inspect(term)}"}
  end

  @spec check_missing_keys(MapSet.t()) :: {:missing, [atom()]}
  defp check_missing_keys(keys) do
    missing =
      @required_keys
      |> MapSet.new()
      |> MapSet.difference(keys)
      |> MapSet.to_list()

    {:missing, missing}
  end

  @spec check_extra_keys(MapSet.t()) :: {:extra, [atom()]}
  defp check_extra_keys(keys) do
    extra =
      keys
      |> MapSet.difference(MapSet.new(@all_keys))
      |> MapSet.to_list()

    {:extra, extra}
  end

  @spec check_constraints(map()) :: :ok | {:error, [binary()]}
  defp check_constraints(map) do
    map
    |> Enum.map(fn {k, v} -> {k, validate_field(k, v)} end)
    |> Enum.filter(&(elem(&1, 1) != :ok))
    |> case do
      [] ->
        :ok

      errors ->
        messages =
          Enum.map(errors, fn {k, {:fail, s}} ->
            [
              "the property ",
              [:bright, :yellow, to_string(k), :reset],
              " violates the constraint ",
              [:bright, :yellow, s, :reset]
            ]
            |> IO.ANSI.format()
            |> IO.iodata_to_binary()
          end)

        {:error, messages}
    end
  end

  rules =
    quote do
      [
        site_name: [is_binary: []],
        site_description: [is_binary: []],
        author: [is_binary: []],
        author_email: [is_binary: []],
        server_root: [is_binary: [], =~: [~r[^https?://.+]]],
        base_url: [is_binary: [], =~: [~r[(^/$|^/.*/$)]]],
        date_format: [is_binary: []],
        list_title_all: [is_binary: []],
        list_title_tag: [is_binary: []],
        pagination: [is_boolean: []],
        posts_per_page: [is_integer: [], >=: [1]],
        preview_length: [valid_preview_length?: []],
        posts_source: [is_binary: []],
        posts_path: [is_binary: []],
        tags_path: [is_binary: []],
        plugins: [is_list: []],
        theme: [is_atom: []]
      ]
    end

  @spec validate_field(atom(), term()) :: :ok | {:fail, binary()}
  defp validate_field(key, value)

  Enum.each(rules, fn {key, exprs} ->
    [x | xs] =
      Enum.map(exprs, fn {func, args} ->
        quote(do: unquote(func)(var!(value), unquote_splicing(args)))
      end)

    check_expr = Enum.reduce(xs, x, &quote(do: unquote(&2) and unquote(&1)))

    [y | ys] =
      Enum.map(exprs, fn {func, args} ->
        quote(do: unquote(func)(value, unquote_splicing(args)))
      end)

    check_str =
      ys
      |> Enum.reduce(y, &quote(do: unquote(&2) and unquote(&1)))
      |> Macro.to_string()

    defp validate_field(unquote(key), value) do
      if unquote(check_expr) do
        :ok
      else
        {:fail, unquote(check_str)}
      end
    end
  end)

  @spec valid_preview_length?(term()) :: boolean()
  defp valid_preview_length?(value)
  defp valid_preview_length?(n) when is_integer(n) and n >= 0, do: true
  defp valid_preview_length?({:chars, n}) when is_integer(n) and n >= 0, do: true
  defp valid_preview_length?({:words, n}) when is_integer(n) and n >= 0, do: true
  defp valid_preview_length?({:paragraphs, n}) when is_integer(n) and n >= 0, do: true
  defp valid_preview_length?(_), do: false
end
