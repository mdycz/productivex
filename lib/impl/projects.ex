defmodule Productive.Impl.Projects do
  @moduledoc false

  alias Productive.{Client, Error, Transport}

  @per_page 50

  @spec get_list(Client.t(), pos_integer()) :: {:ok, map()} | {:error, Error.t()}
  def get_list(client, page) do
    with :ok <- validate_page(page) do
      Transport.request(client, :get, "/projects", params: %{per_page: @per_page, page: page})
    end
  end

  defp validate_page(page) when is_integer(page) and page > 0, do: :ok

  defp validate_page(_page) do
    {:error, Error.validation_error("projects page", %{page: "must be a positive integer"})}
  end
end
