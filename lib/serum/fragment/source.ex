defprotocol Serum.Fragment.Source do
  @moduledoc false

  _moduledocp = """
  Defines a protocol where implementing structs can be converted into
  `Serum.V2.Fragment` structs.
  """

  alias Serum.V2.Fragment
  alias Serum.V2.Result

  @type t :: struct()

  @spec to_fragment(t()) :: Result.t(Fragment.t())
  def to_fragment(fragment_source)
end
