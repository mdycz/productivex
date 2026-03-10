defmodule Productive.Impl.TimeEntries do
  @moduledoc false

  alias Productive.{Client, Error, Transport}

  @page_size 200

  @type id :: String.t() | integer()
  @type time_entry :: %{
          required(:date) => Date.t(),
          required(:time) => non_neg_integer(),
          required(:note) => String.t(),
          required(:service_id) => id()
        }
  @type list_filters :: %{
          required(:project_id) => id(),
          required(:from) => Date.t(),
          required(:to) => Date.t(),
          required(:page) => pos_integer()
        }

  @spec create(Client.t(), time_entry()) :: {:ok, map()} | {:error, Error.t()}
  def create(client, time_entry) do
    with :ok <- validate_time_entry(time_entry) do
      Transport.request(client, :post, "/time_entries", json: create_body(client, time_entry))
    end
  end

  @spec get_list(Client.t(), list_filters()) :: {:ok, map()} | {:error, Error.t()}
  def get_list(client, filters) do
    with :ok <- validate_filters(filters) do
      params =
        filters
        |> Map.put(:person_id, client.person_id)
        |> get_list_query()

      Transport.request(client, :get, "/time_entries", params: params)
    end
  end

  defp create_body(client, time_entry) do
    %{
      data: %{
        type: "time_entries",
        attributes: Map.take(time_entry, [:date, :time, :note]),
        relationships: %{
          person: %{
            data: %{
              type: "people",
              id: client.person_id
            }
          },
          service: %{
            data: %{
              type: "services",
              id: time_entry.service_id
            }
          }
        }
      }
    }
  end

  defp validate_filters(filters) when is_map(filters) do
    errors =
      %{}
      |> validate_id(filters, :project_id)
      |> validate_date(filters, :from)
      |> validate_date(filters, :to)
      |> validate_page(filters, :page)

    if map_size(errors) == 0 do
      case Date.compare(filters.from, filters.to) do
        :gt ->
          {:error,
           Error.validation_error("time entry filters", %{from: "must be on or before to"})}

        _ ->
          :ok
      end
    else
      {:error, Error.validation_error("time entry filters", errors)}
    end
  end

  defp validate_filters(_filters) do
    {:error,
     Error.validation_error("time entry filters", %{
       filters: "must be a map with project_id, from, to, and page"
     })}
  end

  defp validate_time_entry(time_entry) when is_map(time_entry) do
    errors =
      %{}
      |> validate_date(time_entry, :date)
      |> validate_non_negative_integer(time_entry, :time)
      |> validate_string(time_entry, :note, allow_empty?: true)
      |> validate_id(time_entry, :service_id)

    if map_size(errors) == 0 do
      :ok
    else
      {:error, Error.validation_error("time entry", errors)}
    end
  end

  defp validate_time_entry(_time_entry) do
    {:error,
     Error.validation_error("time entry", %{
       time_entry: "must be a map with date, time, note, and service_id"
     })}
  end

  defp get_list_query(%{
         project_id: project_id,
         person_id: person_id,
         from: from,
         to: to,
         page: page
       }) do
    %{
      "filter[project_id]": project_id,
      "filter[person_id]": person_id,
      "filter[after]": Date.to_string(from),
      "filter[before]": Date.to_string(to),
      per_page: @page_size,
      page: page
    }
  end

  defp validate_date(errors, params, key) do
    case Map.get(params, key) do
      %Date{} -> errors
      _ -> Map.put(errors, key, "must be a Date")
    end
  end

  defp validate_id(errors, params, key) do
    case Map.get(params, key) do
      value when is_binary(value) and value != "" -> errors
      value when is_integer(value) -> errors
      _ -> Map.put(errors, key, "must be a non-empty string or integer")
    end
  end

  defp validate_non_negative_integer(errors, params, key) do
    case Map.get(params, key) do
      value when is_integer(value) and value >= 0 -> errors
      _ -> Map.put(errors, key, "must be a non-negative integer")
    end
  end

  defp validate_page(errors, params, key) do
    case Map.get(params, key) do
      value when is_integer(value) and value > 0 -> errors
      _ -> Map.put(errors, key, "must be a positive integer")
    end
  end

  defp validate_string(errors, params, key, allow_empty?: allow_empty?) do
    case Map.get(params, key) do
      value when is_binary(value) and (allow_empty? or value != "") -> errors
      _ -> Map.put(errors, key, "must be a string")
    end
  end
end
