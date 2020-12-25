defmodule Serum.Factory.Posts do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      def post_factory(attrs) do
        {type, attrs} = Map.pop(attrs, :type, "md")
        {source, attrs} = Map.pop(attrs, :source, build(:input_file))
        {project, attrs} = Map.pop(attrs, :project, build(:project))
        {tags, attrs} = Map.pop(attrs, :tags, build_list(3, :tag, project: project))
        dest = String.replace_suffix(source.src, type, "html")

        post = %Serum.V2.Post{
          source: source,
          dest: dest,
          type: "md",
          title: "Hello, world!",
          date: Timex.local(),
          tags: tags,
          url: Path.join([project.base_url.path, project.blog.posts_path, dest]),
          data: source.in_data,
          template: "post",
          extras: %{}
        }

        merge_attributes(post, attrs)
      end
    end
  end
end
