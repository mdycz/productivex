defmodule Productive.Transport do
  @moduledoc false

  alias Productive.{Client, Error}

  @type body :: term()
  @type result :: {:ok, body()} | {:error, Error.t()}

  @spec request(Client.t(), atom(), String.t(), keyword()) :: result()
  def request(client, method, url, options \\ []) do
    client
    |> Client.request_base()
    |> Req.request(Keyword.merge(options, method: method, url: url))
    |> normalize_response()
  end

  defp normalize_response({:ok, %Req.Response{status: status, body: body}})
       when status in 200..299 do
    {:ok, body}
  end

  defp normalize_response({:ok, %Req.Response{status: status, body: body}}) do
    {:error, Error.http_error(status, body)}
  end

  defp normalize_response({:error, exception}) do
    {:error, Error.transport_error(exception)}
  end
end
