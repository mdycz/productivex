defmodule Productive.Error do
  @moduledoc """
  Exception and error container returned by the Productive client.
  """

  @enforce_keys [:kind, :message]
  defexception [:kind, :message, :status, :body, :details]

  @type kind :: :http_error | :invalid_config | :transport_error | :validation_error
  @type t :: %__MODULE__{
          kind: kind(),
          message: String.t(),
          status: pos_integer() | nil,
          body: term(),
          details: term()
        }

  @spec http_error(pos_integer(), term()) :: t()
  def http_error(status, body) do
    %__MODULE__{
      kind: :http_error,
      message: "Productive API request failed with status #{status}",
      status: status,
      body: body,
      details: %{status: status}
    }
  end

  @spec invalid_config(map()) :: t()
  def invalid_config(details) do
    %__MODULE__{
      kind: :invalid_config,
      message: "invalid Productive client configuration",
      details: details
    }
  end

  @spec transport_error(Exception.t()) :: t()
  def transport_error(exception) do
    %__MODULE__{
      kind: :transport_error,
      message: Exception.message(exception),
      details: exception
    }
  end

  @spec validation_error(String.t(), map()) :: t()
  def validation_error(subject, details) do
    %__MODULE__{
      kind: :validation_error,
      message: "invalid #{subject}",
      details: details
    }
  end
end
