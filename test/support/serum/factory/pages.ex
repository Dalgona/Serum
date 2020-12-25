defmodule Serum.Factory.Pages do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      def page_factory(attrs) do
        {type, attrs} = Map.pop(attrs, :type, "md")
        {source, attrs} = Map.pop(attrs, :source, build(:input_file, type: type))
        {project, attrs} = Map.pop(attrs, :project, build(:project))
        dest = String.replace_suffix(source.src, type, "html")

        page = %Serum.V2.Page{
          source: source,
          dest: dest,
          type: "md",
          title: "Hello, world!",
          label: "hello",
          group: "default",
          order: 1,
          url: Path.join(project.base_url.path, dest),
          data: source.in_data,
          template: "page",
          extras: %{}
        }

        merge_attributes(page, attrs)
      end
    end
  end
end
