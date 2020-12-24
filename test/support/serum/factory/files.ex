defmodule Serum.Factory.Files do
  @moduledoc false

  defmacro __using__(_opts) do
    quote do
      def file_name_factory(attrs) do
        type = attrs[:type] || "md"
        name_fun = &Path.join(attrs[:relative_to] || "", "file_#{&1}.#{type}")

        sequence(:file_name, name_fun)
      end

      def input_file_factory(attrs) do
        src =
          case attrs[:src] do
            str when is_binary(str) -> str
            _ -> build(:file_name, attrs)
          end

        %Serum.V2.File{
          src: src,
          in_data: attrs[:in_data] || "Lorem ipsum dolor sit amet."
        }
      end

      def output_file_factory(attrs) do
        dest =
          case attrs[:dest] do
            str when is_binary(str) -> str
            _ -> build(:file_name, attrs)
          end

        %Serum.V2.File{
          dest: dest,
          out_data: attrs[:out_data] || "Lorem ipsum dolor sit amet."
        }
      end
    end
  end
end
