defmodule Serum.Project.ElixirValidator do
  @moduledoc false

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
    :preview_length
  ]

  @required_keys [
    :site_name,
    :site_description,
    :author,
    :author_email,
    :base_url
  ]

  @spec validate(map(), binary()) :: Result.t()
  def validate(term, path)

  def validate(%{} = map, path) do
    keys = map |> Map.keys() |> MapSet.new()

    with {:missing, []} <- check_missing_keys(keys),
         {:extra, []} <- check_extra_keys(keys),
         :ok <- check_constraints(map) do
      :ok
    else
      {:missing, [x]} ->
        {:error, {"missing required property: #{x}", path, 0}}

      {:missing, xs} ->
        props_str = Enum.join(xs, ", ")

        {:error, {"missing required properties: #{props_str}", path, 0}}

      {:extra, [x]} ->
        {:error, {"unknown property: #{x}", path, 0}}

      {:extra, xs} ->
        props_str = Enum.join(xs, ", ")

        {:error, {"unknown properties: #{props_str}", path, 0}}

      {:error, messages} ->
        sub_errors = Enum.map(messages, &{:error, {&1, path, 0}})

        {:error, {:project_validator, sub_errors}}
    end
  end

  def validate(term, path) do
    {:error, {"expected a map, got: #{inspect(term)}", path, 0}}
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
            prop = "\x1b[1;33m#{k}\x1b[0m"
            constraint = "\x1b[1;33m#{s}\x1b[0m"

            "the property #{prop} violates the constraint #{constraint}"
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
        preview_length: [is_integer: [], >=: [0]]
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
end
