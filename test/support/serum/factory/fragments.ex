defmodule Serum.Factory.Fragments do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      def fragment_factory(attrs) do
        {from, attrs} = Map.pop(attrs, :from, build(:page))

        fragment = %Serum.V2.Fragment{
          source: Map.get(from, :source),
          dest: from.dest,
          metadata: from,
          data: Map.get(from, :in_data, "Hello, world!")
        }

        merge_attributes(fragment, attrs)
      end
    end
  end
end
