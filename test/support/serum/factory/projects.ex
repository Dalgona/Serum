defmodule Serum.Factory.Projects do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      def project_factory(attrs) do
        {base_url, attrs} = Map.pop(attrs, :base_url, "https://example.com/my-website")
        {blog, attrs} = Map.pop(attrs, :blog, %{})

        project = %Serum.V2.Project{
          title: "My Website",
          description: "Welcome to my website.",
          base_url: URI.parse(base_url),
          authors: %{
            john: %{
              name: "John Doe",
              email: "john.doe@example.com"
            }
          },
          blog: struct!(Serum.V2.Project.BlogConfiguration, blog),
          theme: nil,
          plugins: []
        }

        merge_attributes(project, attrs)
      end
    end
  end
end
