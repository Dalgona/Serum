defmodule Serum.Factory.GlobalBindings do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      def global_bindings_factory do
        project = build(:project)
        tags = build_list(3, :tag, project: project)
        posts = Enum.map(tags, &build(:post, project: project, tags: [&1]))

        %{
          all_pages: build_list(3, :page, project: project),
          all_posts: posts,
          all_tags: Enum.map(tags, &{&1, 1}),
          project: project
        }
      end
    end
  end
end
