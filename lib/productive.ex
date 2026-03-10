defmodule Productive do
  @moduledoc """
  Productive REST API client.
  """

  alias Productive.Impl.{Projects, Services, TimeEntries}
  alias Productive.{Client, Error}

  @type result :: {:ok, map()} | {:error, Error.t()}

  @spec create_time_entry(Client.t(), TimeEntries.time_entry()) :: result()
  def create_time_entry(client, time_entry), do: TimeEntries.create(client, time_entry)

  @spec create_time_entry!(Client.t(), TimeEntries.time_entry()) :: map()
  def create_time_entry!(client, time_entry), do: unwrap!(create_time_entry(client, time_entry))

  @spec get_time_entries(Client.t(), TimeEntries.list_filters()) :: result()
  def get_time_entries(client, filters), do: TimeEntries.get_list(client, filters)

  @spec get_time_entries!(Client.t(), TimeEntries.list_filters()) :: map()
  def get_time_entries!(client, filters), do: unwrap!(get_time_entries(client, filters))

  @spec get_projects(Client.t(), pos_integer()) :: result()
  def get_projects(client, page), do: Projects.get_list(client, page)

  @spec get_projects!(Client.t(), pos_integer()) :: map()
  def get_projects!(client, page), do: unwrap!(get_projects(client, page))

  @doc """
  Returns budgeted services for a project.
  """
  @spec get_services(Client.t(), String.t() | integer(), pos_integer()) :: result()
  def get_services(client, project_id, page), do: Services.get_list(client, project_id, page)

  @spec get_services!(Client.t(), String.t() | integer(), pos_integer()) :: map()
  def get_services!(client, project_id, page), do: unwrap!(get_services(client, project_id, page))

  defp unwrap!({:ok, body}), do: body
  defp unwrap!({:error, %Error{} = error}), do: raise(error)
end
