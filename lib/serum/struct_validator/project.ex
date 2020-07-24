defmodule Serum.StructValidator.Project do
  @moduledoc false

  _moduledocp = "A module for validating Serum project configuration."

  use Serum.StructValidator

  define_validator do
    key :title, required: true, rules: [is_binary: []]
    key :description, rules: [is_binary: []]
    key :base_url, required: true, rules: [is_binary: [], =~: [~r[^https?://]]]
    key :authors, rules: [is_map: []]
    key :blogs, rules: [map_or_false?: []]
    key :theme, rules: [valid_theme_spec?: []]
    key :plugins, rules: [is_list: []]
  end

  @spec map_or_false?(term()) :: boolean()
  defp map_or_false?(value)
  defp map_or_false?(%{}), do: true
  defp map_or_false?(false), do: true
  defp map_or_false?(_), do: false

  @spec valid_theme_spec?(term()) :: boolean()
  defp valid_theme_spec?(value)
  defp valid_theme_spec?(nil), do: true
  defp valid_theme_spec?(module) when is_atom(module), do: true

  defp valid_theme_spec?({module, opts})
       when not is_nil(module) and is_atom(module) and is_list(opts) do
    true
  end

  defp valid_theme_spec?(_), do: false
end
