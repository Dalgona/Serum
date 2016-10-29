defmodule Serum.Error do
  @moduledoc """
  This module defines types for positive results or errors returned by
  functions in this project.
  """

  @type result :: positive | error

  @type positive :: :ok | {:ok, term}

  @type error :: {:error, reason, err_details}

  @type reason :: atom

  @type err_details :: no_detail | msg_detail | full_detail | nest_detail

  @type no_detail   :: nil
  @type msg_detail  :: message
  @type full_detail :: {message, file, line}
  @type nest_detail :: [error]

  @type message :: atom | String.t
  @type file    :: String.t
  @type line    :: non_neg_integer
end

defmodule Serum.PageTypeError do
  defexception [type: nil]

  def message(e) do
    "page filetype must be either `md` or `html`, got `#{e.type}`"
  end
end
