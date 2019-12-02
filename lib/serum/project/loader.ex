defmodule Serum.Project.Loader do
  @moduledoc false

  _moduledocp = "A module for loading Serum project definition files."

  require Serum.Result, as: Result
  alias Serum.Error
  alias Serum.Error.ExceptionMessage
  alias Serum.Error.POSIXMessage
  alias Serum.Error.SimpleMessage
  alias Serum.GlobalBindings
  alias Serum.Project
  alias Serum.Project.ElixirValidator
  alias Serum.Theme

  @doc """
  Detects and loads Serum project definition file from the source directory.
  """
  @spec load(binary(), binary()) :: Result.t(Project.t())
  def load(src, dest) do
    case do_load(src) do
      {:ok, %Project{} = proj} ->
        GlobalBindings.put(:site, %{
          name: proj.site_name,
          description: proj.site_description,
          author: proj.author,
          author_email: proj.author_email,
          server_root: proj.server_root,
          base_url: proj.base_url
        })

        Result.return(%Project{proj | src: src, dest: dest})

      {:error, %Error{}} = error ->
        error
    end
  end

  @spec do_load(binary()) :: Result.t(Project.t())
  defp do_load(src) do
    exs_path = Path.join(src, "serum.exs")

    if File.exists?(exs_path) do
      load_exs(exs_path)
    else
      {:error,
       %Error{
         message: %POSIXMessage{reason: :enoent},
         caused_by: [],
         file: %Serum.File{src: exs_path}
       }}
    end
  end

  @spec load_exs(binary()) :: Result.t(Project.t())
  defp load_exs(exs_path) do
    with {:ok, data} <- File.read(exs_path),
         {map, _} <- Code.eval_string(data, [], file: exs_path),
         :ok <- ElixirValidator.validate(map) do
      Result.return(Project.new(Map.put(map, :theme, %Theme{module: map[:theme]})))
    else
      # From File.read/1:
      {:error, reason} when is_atom(reason) ->
        {:error,
         %Error{
           message: %POSIXMessage{reason: reason},
           caused_by: [],
           file: %Serum.File{src: exs_path}
         }}

      # From ElixirValidator.validate/2:
      {:invalid, message} when is_binary(message) ->
        {:error,
         %Error{
           message: %SimpleMessage{text: message},
           caused_by: [],
           file: %Serum.File{src: exs_path}
         }}

      {:invalid, messages} when is_list(messages) ->
        errors =
          Enum.map(messages, fn message ->
            {:error,
             %Error{
               message: %SimpleMessage{text: message},
               caused_by: [],
               file: %Serum.File{src: exs_path}
             }}
          end)

        Result.aggregate_values(errors, "failed to validate `serum.exs`:")
    end
  rescue
    e in [CompileError, SyntaxError, TokenMissingError] ->
      {:error,
       %Error{
         message: %ExceptionMessage{exception: e, stacktrace: __STACKTRACE__},
         caused_by: [],
         file: %Serum.File{src: e.file},
         line: e.line
       }}

    e ->
      {:error,
       %Error{
         message: %ExceptionMessage{exception: e, stacktrace: __STACKTRACE__},
         caused_by: [],
         file: %Serum.File{src: exs_path}
       }}
  end
end
