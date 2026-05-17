defmodule Productive.Impl.Invoices do
  @moduledoc false

  alias Productive.{Client, Error, Transport}

  @per_page 50

  @type id :: String.t() | integer()
  @type list_filters :: %{
          optional(:page) => pos_integer(),
          optional(:after) => DateTime.t(),
          optional(:company_id) => id()
        }

  @spec get_list(Client.t(), list_filters()) :: {:ok, map()} | {:error, Error.t()}
  def get_list(client, filters) when is_map(filters) do
    with :ok <- validate_filters(filters) do
      Transport.request(client, :get, "/invoices", params: build_params(filters))
    end
  end

  def get_list(_client, _filters),
    do: {:error, Error.validation_error("invoice filters", %{filters: "must be a map"})}

  @spec get(Client.t(), id()) :: {:ok, map()} | {:error, Error.t()}
  def get(client, id) do
    with :ok <- validate_id(id) do
      Transport.request(client, :get, "/invoices/#{id}",
        params: %{include: "line_items,bill_from"}
      )
    end
  end

  defp build_params(filters) do
    page = Map.get(filters, :page, 1)

    base = %{
      page: page,
      per_page: @per_page,
      include: "line_items,bill_from"
    }

    base
    |> maybe_put_after(filters)
    |> maybe_put_company(filters)
  end

  defp maybe_put_after(params, %{after: %DateTime{} = ts}),
    do: Map.put(params, :"filter[after]", DateTime.to_iso8601(ts))

  defp maybe_put_after(params, _), do: params

  defp maybe_put_company(params, %{company_id: id}) when is_binary(id) or is_integer(id),
    do: Map.put(params, :"filter[company_id]", id)

  defp maybe_put_company(params, _), do: params

  defp validate_filters(filters) do
    errors =
      %{}
      |> validate_page(filters)
      |> validate_after(filters)
      |> validate_company_id(filters)

    if map_size(errors) == 0,
      do: :ok,
      else: {:error, Error.validation_error("invoice filters", errors)}
  end

  defp validate_page(errors, %{page: page}) when is_integer(page) and page > 0, do: errors
  defp validate_page(errors, %{page: _}), do: Map.put(errors, :page, "must be a positive integer")
  defp validate_page(errors, _), do: errors

  defp validate_after(errors, %{after: %DateTime{}}), do: errors
  defp validate_after(errors, %{after: _}), do: Map.put(errors, :after, "must be a DateTime")
  defp validate_after(errors, _), do: errors

  defp validate_company_id(errors, %{company_id: id}) when is_binary(id) and id != "", do: errors
  defp validate_company_id(errors, %{company_id: id}) when is_integer(id), do: errors

  defp validate_company_id(errors, %{company_id: _}),
    do: Map.put(errors, :company_id, "must be a non-empty string or integer")

  defp validate_company_id(errors, _), do: errors

  defp validate_id(value) when (is_binary(value) and value != "") or is_integer(value), do: :ok

  defp validate_id(_),
    do:
      {:error,
       Error.validation_error("invoice id", %{id: "must be a non-empty string or integer"})}
end
