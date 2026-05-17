defmodule Productive.Impl.Companies do
  @moduledoc false

  alias Productive.{Client, Error, Transport}

  @per_page 50

  @type id :: String.t() | integer()

  @spec get_list(Client.t(), %{optional(:page) => pos_integer()}) ::
          {:ok, map()} | {:error, Error.t()}
  def get_list(client, filters \\ %{}) when is_map(filters) do
    page = Map.get(filters, :page, 1)

    with :ok <- validate_page(page) do
      Transport.request(client, :get, "/companies", params: %{page: page, per_page: @per_page})
    end
  end

  @spec get(Client.t(), id()) :: {:ok, map()} | {:error, Error.t()}
  def get(client, id) do
    with :ok <- validate_id(id) do
      Transport.request(client, :get, "/companies/#{id}")
    end
  end

  defp validate_page(page) when is_integer(page) and page > 0, do: :ok

  defp validate_page(_page),
    do: {:error, Error.validation_error("companies page", %{page: "must be a positive integer"})}

  defp validate_id(value) when (is_binary(value) and value != "") or is_integer(value), do: :ok

  defp validate_id(_),
    do:
      {:error,
       Error.validation_error("company id", %{id: "must be a non-empty string or integer"})}
end
