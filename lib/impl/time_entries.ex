defmodule Productive.Impl.TimeEntries do
  alias Productive.Client

  @page_size 200

  @type time_entry :: %{date: Date.t(), time: integer(), note: String.t(), service_id: String.t()}

  def create(client, time_entry) do
    Client.request_base(client)
    |> Req.post!(
      url: "/time_entries",
      json: create_body(client, time_entry)
    )
  end

  def get_list(client, filters) do
    params =
      filters
      |> Map.merge(%{person_id: client.person_id})
      |> get_list_query()

    Req.get!(Client.request_base(client), url: "/time_entries", params: params).body
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
end
