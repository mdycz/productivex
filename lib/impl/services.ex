defmodule Productive.Impl.Services do
  @per_page 50

  def get_list(client, project_id, page) do
    client
    |> Productive.Client.request_base()
    |> Req.get!(
      url: "/services",
      params: %{
        "filter[project_id]": project_id,
        "filter[budget_status]": 1,
        per_page: @per_page,
        page: page
      }
    )
  end
end
