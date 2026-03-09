defmodule Productive do
  @moduledoc """
  Wrapper for Productive REST API
  """
  alias Productive.Impl.TimeEntries
  alias Productive.Impl.Projects
  alias Productive.Impl.Services

  @spec create_time_entry(%Productive.Client{}, TimeEntries.time_entry()) :: any()
  defdelegate create_time_entry(client, time_entry), to: TimeEntries, as: :create

  @spec get_time_entries(%Productive.Client{}, any()) :: list(any())
  defdelegate get_time_entries(client, filters), to: TimeEntries, as: :get_list

  @spec get_projects(%Productive.Client{}, integer()) :: list(any())
  defdelegate get_projects(client, page), to: Projects, as: :get_list

  @spec get_services(%Productive.Client{}, integer(), integer()) :: list(any())
  defdelegate get_services(client, project_id, page), to: Services, as: :get_list
end
