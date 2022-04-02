defmodule Serum.Post.PreviewGenerator do
  @moduledoc false

  _moduledocp = "Generates a preview text from a blog post."

  @spec generate_preview(binary(), term()) :: binary()
  def generate_preview(html, length)
  def generate_preview(_html, l) when is_integer(l) and l <= 0, do: ""
  def generate_preview(_html, {_, l}) when is_integer(l) and l <= 0, do: ""

  def generate_preview(html, l) when is_integer(l) do
    html |> Floki.parse_document!() |> do_generate_preview({:chars, l})
  end

  def generate_preview(html, {_, l} = lspec) when is_integer(l) do
    html |> Floki.parse_document!() |> do_generate_preview(lspec)
  end

  def generate_preview(_html, _), do: ""

  @spec do_generate_preview(Floki.html_tree(), {term(), non_neg_integer()}) :: binary()
  defp do_generate_preview(html, lspec)

  defp do_generate_preview(html_tree, {:chars, l}) do
    html_tree
    |> Floki.text(sep: " ")
    |> String.trim()
    |> String.replace(~r/\s+/, " ")
    |> String.slice(0, l)
    |> Kernel.<>("\u2026")
  end

  defp do_generate_preview(html_tree, {:words, l}) do
    html_tree
    |> Floki.text(sep: " ")
    |> String.split(~r/\s/, trim: true)
    |> Enum.take(l)
    |> Enum.join(" ")
    |> Kernel.<>("\u2026")
  end

  defp do_generate_preview(html_tree, {:paragraphs, l}) do
    html_tree
    |> Floki.find("p")
    |> Enum.take(l)
    |> Enum.map_join(" ", &(&1 |> Floki.text() |> String.trim()))
    |> Kernel.<>("\u2026")
  end

  defp do_generate_preview(_html_tree, _), do: ""
end
