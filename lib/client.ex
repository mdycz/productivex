defmodule Productive.Client do
  @moduledoc """
  Client configuration used by Productive API calls.
  """

  alias Productive.Error

  @base_url "https://api.productive.io/api/v2"
  @required_fields ~w(auth_token organization_id person_id)a

  @enforce_keys [:auth_token, :person_id, :organization_id]
  defstruct [:auth_token, :person_id, :organization_id]

  @type t :: %__MODULE__{
          auth_token: String.t(),
          person_id: String.t(),
          organization_id: String.t()
        }

  @type config :: %{
          required(:auth_token) => String.t(),
          required(:person_id) => String.t(),
          required(:organization_id) => String.t()
        }

  @spec new(t() | config() | keyword()) :: {:ok, t()} | {:error, Error.t()}
  def new(%__MODULE__{} = client), do: {:ok, client}

  def new(config) when is_list(config) do
    config
    |> Enum.into(%{})
    |> new()
  end

  def new(config) when is_map(config) do
    case validate_config(config) do
      :ok ->
        attrs = Map.take(config, @required_fields)
        {:ok, struct!(__MODULE__, attrs)}

      {:error, details} ->
        {:error, Error.invalid_config(details)}
    end
  end

  def new(config) do
    {:error,
     Error.invalid_config(%{
       config: "must be a map, keyword list, or Productive.Client",
       value: config
     })}
  end

  @spec new!(t() | config() | keyword()) :: t()
  def new!(config) do
    case new(config) do
      {:ok, client} -> client
      {:error, %Error{} = error} -> raise error
    end
  end

  @spec request_base(t()) :: Req.Request.t()
  def request_base(client) do
    [base_url: @base_url, headers: headers(client)]
    |> Keyword.merge(Application.get_env(:productive, :req_options, []))
    |> Req.new()
  end

  defp validate_config(config) do
    errors =
      Enum.reduce(@required_fields, %{}, fn field, acc ->
        case Map.get(config, field) do
          value when is_binary(value) and value != "" ->
            acc

          _ ->
            Map.put(acc, field, "must be a non-empty string")
        end
      end)

    if map_size(errors) == 0, do: :ok, else: {:error, errors}
  end

  defp headers(client) do
    %{
      Accept: "application/vnd.api+json",
      "X-Auth-Token": client.auth_token,
      "X-Organization-Id": client.organization_id,
      "Content-Type": "application/vnd.api+json"
    }
  end
end
