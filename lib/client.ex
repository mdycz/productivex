defmodule Productive.Client do
  @base_url "https://api.productive.io/api/v2"

  @enforce_keys [:auth_token, :person_id, :organization_id]
  defstruct [:auth_token, :person_id, :organization_id]

  def new(config) do
    struct(__MODULE__, config)
  end

  def request_base(client) do
    [base_url: @base_url, headers: headers(client)]
    |> Keyword.merge(Application.get_env(:productive, :req_options, []))
    |> Req.new()
  end

  defp headers(client) do
    %{
      "X-Auth-Token": client.auth_token,
      "X-Organization-Id": client.organization_id,
      "Content-Type": "application/vnd.api+json"
    }
  end
end
