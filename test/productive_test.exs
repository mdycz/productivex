defmodule ProductiveTest do
  use ExUnit.Case, async: false

  setup do
    Application.put_env(:productive, :req_options, plug: {Req.Test, Productive.Client})

    on_exit(fn ->
      Application.delete_env(:productive, :req_options)
    end)
  end

  test "get_projects/2 delegates to the Productive API" do
    Req.Test.stub(Productive.Client, fn conn ->
      assert String.ends_with?(conn.request_path, "/projects")
      Req.Test.json(conn, %{"data" => [%{"id" => "project-1"}]})
    end)

    client =
      Productive.Client.new(%{
        auth_token: "productive-token",
        person_id: "person-1",
        organization_id: "org-1"
      })

    response = Productive.get_projects(client, 1)

    assert response.body == %{"data" => [%{"id" => "project-1"}]}
  end

  test "get_services/3 delegates to the Productive API" do
    Req.Test.stub(Productive.Client, fn conn ->
      assert String.ends_with?(conn.request_path, "/services")
      Req.Test.json(conn, %{"data" => [%{"id" => "service-1"}]})
    end)

    client =
      Productive.Client.new(%{
        auth_token: "productive-token",
        person_id: "person-1",
        organization_id: "org-1"
      })

    response = Productive.get_services(client, "project-1", 1)

    assert response.body == %{"data" => [%{"id" => "service-1"}]}
  end
end
