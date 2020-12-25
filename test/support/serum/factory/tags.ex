defmodule Serum.Factory.Tags do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      def tag_factory(attrs) do
        {name, attrs} = Map.pop(attrs, :name, sequence(:tag_name, &"tag_#{&1}"))
        {project, attrs} = Map.pop(attrs, :project, build(:project))

        tag = %Serum.V2.Tag{
          name: name,
          path: Path.join([project.base_url.path, project.blog.tags_path, name])
        }

        merge_attributes(tag, attrs)
      end
    end
  end
end
