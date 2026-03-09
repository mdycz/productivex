defmodule Productive.Impl.Projects do
  @per_page 50

  def get_list(client, page) do
    client
    |> Productive.Client.request_base()
    |> Req.get!(url: "/projects", params: %{per_page: @per_page, page: page})
  end
end
