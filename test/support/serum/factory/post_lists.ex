defmodule Serum.Factory.PostLists do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      def post_list_factory(attrs) do
        {project, attrs} = Map.pop(attrs, :project, build(:project))
        {tag, attrs} = Map.pop(attrs, :tag, build(:tag, project: project))
        {current_page, attrs} = Map.pop(attrs, :current_page, 1)
        {last_page, attrs} = Map.pop(attrs, :last_page, 1)
        tags = List.wrap(tag)

        {posts, attrs} =
          Map.pop(attrs, :posts, build_list(3, :post, project: project, tags: tags))

        dest = Path.join(tag.path, "page-#{current_page}.html")

        title =
          case tag do
            nil -> project.blog.list_title_all
            tag -> :io_lib.format(project.blog.list_title_tag, [tag.name])
          end

        list = %Serum.V2.PostList{
          tag: tag,
          current_page: 1,
          last_page: 1,
          title: to_string(title),
          posts: posts,
          url: dest,
          dest: dest,
          extras: %{}
        }

        merge_attributes(list, attrs)
      end
    end
  end
end
