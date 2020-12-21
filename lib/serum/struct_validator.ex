defmodule Serum.StructValidator do
  @moduledoc false

  require Serum.V2.Result, as: Result
  alias Serum.ForeignCode
  alias Serum.V2.Error

  @spec __using__(term()) :: Macro.t()
  defmacro __using__(_opts) do
    quote do
      require Serum.V2.Result, as: Result
      import unquote(__MODULE__), only: [define_validator: 1]
    end
  end

  @spec define_validator(keyword()) :: Macro.t()
  defmacro define_validator(do: do_block) do
    exprs = extract_block(do_block)

    quote do
      import unquote(__MODULE__), only: [key: 2]

      used_module = unquote(__MODULE__)
      key_specs = unquote(exprs)
      all_keys = key_specs |> Keyword.keys() |> MapSet.new() |> Macro.escape()

      required_keys =
        key_specs
        |> Enum.filter(&elem(&1, 1)[:required])
        |> Keyword.keys()
        |> MapSet.new()
        |> Macro.escape()

      unquote(def_validate_expr())

      @spec _validate_field(atom(), term()) :: Result.t({})
      def _validate_field(key, value)

      Enum.map(key_specs, fn {name, opts} ->
        rules = opts[:rules] || []

        check_expr =
          rules
          |> Enum.map(fn {func, args} ->
            escaped_args = Enum.map(args, &Macro.escape/1)

            quote(do: unquote(func)(var!(value), unquote_splicing(escaped_args)))
          end)
          |> Enum.reduce(&quote(do: unquote(&2) and unquote(&1)))

        check_str =
          rules
          |> Enum.map(fn {func, args} ->
            quote(do: unquote(func)(value, unquote_splicing(args)))
          end)
          |> Enum.reduce(&quote(do: unquote(&2) and unquote(&1)))
          |> Macro.to_string()

        unquote(def_validate_field_expr())
      end)
    end
  end

  @spec key(atom(), keyword()) :: Macro.t()
  defmacro key(name, opts), do: quote(do: {unquote(name), unquote(opts)})

  @spec extract_block(Macro.t()) :: [Macro.t()]
  defp extract_block(maybe_block_expr)
  defp extract_block({:__block__, _, exprs}) when is_list(exprs), do: exprs
  defp extract_block(expr), do: [expr]

  @spec def_validate_expr() :: Macro.t()
  defp def_validate_expr do
    quote unquote: false do
      @spec validate(term()) :: Result.t({})
      def validate(term) do
        unquote(used_module)._validate(
          term,
          __MODULE__,
          unquote(all_keys),
          unquote(required_keys)
        )
      end

      defoverridable validate: 1
    end
  end

  @spec def_validate_field_expr() :: Macro.t()
  defp def_validate_field_expr do
    quote unquote: false do
      def _validate_field(unquote(name) = name, var!(value)) do
        if unquote(check_expr) do
          Result.return()
        else
          Result.fail(Constraint: [name, var!(value), unquote(check_str)])
        end
      end
    end
  end

  @doc false
  @spec _validate(term(), module(), term(), term()) :: Result.t({})
  def _validate(value, module, all_keys, required_keys) do
    module_name = ForeignCode.module_name(module)
    fail_message = "validation for #{module_name} struct failed:"

    value
    |> do_validate(module, all_keys, required_keys)
    |> case do
      {:ok, _} ->
        Result.return()

      {:error, %Error{caused_by: errors} = error} ->
        Result.fail(
          Simple: [fail_message],
          caused_by: if(Enum.empty?(errors), do: [error], else: errors)
        )
    end
  end

  @spec do_validate(term(), module(), term(), term()) :: Result.t({})
  defp do_validate(term, module, all_keys, required_keys)

  defp do_validate(%{} = map, module, all_keys, required_keys) do
    keys = map |> Map.keys() |> MapSet.new()

    Result.run do
      compare_key_sets(required_keys, keys, "missing required")
      compare_key_sets(keys, all_keys, "unknown")

      map
      |> Enum.map(fn {key, value} -> module._validate_field(key, value) end)
      |> Result.aggregate("")
    end
  end

  defp do_validate(term, _module, _all_keys, _required_keys) do
    Result.fail(Simple: ["expected a map, got: #{inspect(term)}"])
  end

  @spec compare_key_sets(term(), term(), binary()) :: Result.t({})
  defp compare_key_sets(keys1, keys2, message_prefix) do
    keys1
    |> MapSet.difference(keys2)
    |> MapSet.to_list()
    |> case do
      [] ->
        Result.return()

      difference when is_list(difference) ->
        prop_word = pluralize_property(difference)
        keys_str = Enum.join(difference, ", ")

        Result.fail(Simple: ["#{message_prefix} #{prop_word}: #{keys_str}"])
    end
  end

  @spec pluralize_property(list()) :: binary()
  defp pluralize_property(list)
  defp pluralize_property([_]), do: "property"
  defp pluralize_property([_ | _]), do: "properties"
end
