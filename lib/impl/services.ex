defmodule Productive.Impl.Services do
  @moduledoc false

  alias Productive.{Client, Error, Transport}

  @per_page 50

  @spec get_list(Client.t(), String.t() | integer(), pos_integer()) ::
          {:ok, map()} | {:error, Error.t()}
  def get_list(client, project_id, page) do
    with :ok <- validate_project_id(project_id),
         :ok <- validate_page(page) do
      Transport.request(client, :get, "/services",
        params: %{
          "filter[project_id]": project_id,
          "filter[budget_status]": 1,
          per_page: @per_page,
          page: page
        }
      )
    end
  end

  defp validate_project_id(project_id) when is_binary(project_id) and project_id != "", do: :ok
  defp validate_project_id(project_id) when is_integer(project_id), do: :ok

  defp validate_project_id(_project_id) do
    {:error,
     Error.validation_error("services project_id", %{
       project_id: "must be a non-empty string or integer"
     })}
  end

  defp validate_page(page) when is_integer(page) and page > 0, do: :ok

  defp validate_page(_page) do
    {:error, Error.validation_error("services page", %{page: "must be a positive integer"})}
  end
end
