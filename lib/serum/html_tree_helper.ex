defmodule Serum.HtmlTreeHelper do
  @moduledoc "Provides useful functions for working with HTML trees."

  @type tree :: binary() | tag() | [binary() | tag()]
  @type tag :: {binary(), [attribute()], [tree()]}
  @type attribute :: {binary(), binary()}
  @type tree_fun :: (tree() -> tree())
  @type acc_tree_fun :: (tree(), term() -> {tree(), term()})

  @doc """
  Performs a post-order traversal of the given HTML tree.
  """
  @spec traverse(tree(), tree_fun()) :: tree()
  def traverse(tree, fun)

  def traverse({tag_name, attrs, children}, fun) do
    new_children = traverse(children, fun)

    fun.({tag_name, attrs, new_children})
  end

  def traverse(tags, fun) when is_list(tags) do
    Enum.map(tags, &traverse(&1, fun))
  end

  def traverse(x, _fun), do: x

  @doc """
  Performs a post-order traversal of the given HTML tree with an accumulator.
  """
  @spec traverse(tree(), term(), acc_tree_fun()) :: {tree(), term()}
  def traverse(tree, acc, fun)

  def traverse({tag_name, attrs, children}, acc, fun) do
    {new_children, new_acc} = traverse(children, acc, fun)

    fun.({tag_name, attrs, new_children}, new_acc)
  end

  def traverse(tags, acc, fun) when is_list(tags) do
    {new_tags, new_acc} =
      Enum.reduce(tags, {[], acc}, fn tag, {list, acc} ->
        {new_tag, new_acc2} = traverse(tag, acc, fun)

        {[new_tag | list], new_acc2}
      end)

    {new_tags |> Enum.reverse() |> List.flatten(), new_acc}
  end

  def traverse(x, acc, _fun), do: {x, acc}
end
