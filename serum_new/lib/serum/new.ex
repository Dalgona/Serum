defmodule Serum.New do
  @moduledoc false

  @elixir_version Version.parse!(System.version())

  @doc false
  @spec process_path(binary(), boolean()) :: {:ok, binary()} | {:error, binary()}
  def process_path(path, force?) do
    with :ok <- check_path(path, force?),
         app_name = Path.basename(Path.expand(path)),
         :ok <- check_app_name(app_name) do
      {:ok, app_name}
    else
      {:error, _} = error -> error
    end
  end

  @spec check_path(binary(), boolean()) :: :ok | {:error, binary()}
  defp check_path(path, force?)
  defp check_path(_path, true), do: :ok

  defp check_path(path, false) do
    if File.exists?(path) do
      case File.ls!(path) do
        [] ->
          :ok

        xs when is_list(xs) ->
          {:error,
           "#{path} already exists and is not empty. " <>
             "Try again with a --force option to override"}
      end
    else
      :ok
    end
  end

  @spec check_app_name(binary()) :: :ok | {:error, binary()}
  defp check_app_name(app_name) do
    if app_name =~ ~r/^[a-z][a-z0-9_]*$/ do
      :ok
    else
      {:error,
       "PATH must start with a lowercase ASCII letter, " <>
         "followed by zero or more lowercase ASCII letters, digits, " <>
         "or underscores. Got: #{inspect(app_name)}"}
    end
  end

  @doc false
  @spec get_elixir_version!() :: binary()
  def get_elixir_version!, do: get_version_req(@elixir_version)

  @doc false
  @spec get_serum_dep() :: binary()

  if Mix.env() === :prod do
    ver = Version.parse!(Mix.Project.config()[:version])

    pre_release =
      case ver.pre do
        [] -> ""
        [x | _xs] -> "-#{x}"
      end

    def get_serum_dep do
      unquote(~s({:serum, "~> #{ver.major}.#{ver.minor}#{pre_release}"}))
    end
  else
    def get_serum_dep do
      ~s({:serum, path: "#{Path.expand(Path.join(File.cwd!(), ".."))}"})
    end
  end

  @doc false
  @spec create_file(binary(), iodata()) :: any()
  def create_file(path, data) do
    Mix.Generator.create_file(path, data, force: true)
  end

  @doc false
  @spec get_version_req(Version.t()) :: binary()
  def get_version_req(version) do
    pre_release =
      case version.pre do
        [] -> ""
        [x | _xs] -> "-#{x}"
      end

    "#{version.major}.#{version.minor}#{pre_release}"
  end
end
