defmodule ProductiveTest do
  use ExUnit.Case, async: false

  setup do
    Application.put_env(:productive, :req_options,
      plug: {Req.Test, Productive.Client},
      retry: false
    )

    on_exit(fn ->
      Application.delete_env(:productive, :req_options)
    end)

    client =
      Productive.Client.new!(%{
        auth_token: "productive-token",
        person_id: "person-1",
        organization_id: "org-1"
      })

    %{client: client}
  end

  test "client new/1 validates required fields" do
    assert {:error, %Productive.Error{kind: :invalid_config, details: details}} =
             Productive.Client.new(%{auth_token: "", person_id: "person-1"})

    assert details == %{
             auth_token: "must be a non-empty string",
             organization_id: "must be a non-empty string"
           }
  end

  test "get_projects/2 returns decoded body with headers and params", %{client: client} do
    Req.Test.stub(Productive.Client, fn conn ->
      assert String.ends_with?(conn.request_path, "/projects")
      assert conn.query_string == "page=1&per_page=50"
      assert Plug.Conn.get_req_header(conn, "accept") == ["application/vnd.api+json"]
      assert Plug.Conn.get_req_header(conn, "x-auth-token") == ["productive-token"]
      assert Plug.Conn.get_req_header(conn, "x-organization-id") == ["org-1"]
      Req.Test.json(conn, %{"data" => [%{"id" => "project-1"}]})
    end)

    assert {:ok, %{"data" => [%{"id" => "project-1"}]}} = Productive.get_projects(client, 1)
  end

  test "get_services/3 returns decoded body", %{client: client} do
    Req.Test.stub(Productive.Client, fn conn ->
      assert String.ends_with?(conn.request_path, "/services")

      assert URI.decode_query(conn.query_string) == %{
               "filter[budget_status]" => "1",
               "filter[project_id]" => "project-1",
               "page" => "1",
               "per_page" => "50"
             }

      Req.Test.json(conn, %{"data" => [%{"id" => "service-1"}]})
    end)

    assert {:ok, %{"data" => [%{"id" => "service-1"}]}} =
             Productive.get_services(client, "project-1", 1)
  end

  test "get_time_entries/2 returns decoded body and injects person filter", %{client: client} do
    Req.Test.stub(Productive.Client, fn conn ->
      assert String.ends_with?(conn.request_path, "/time_entries")

      assert URI.decode_query(conn.query_string) == %{
               "filter[after]" => "2026-03-01",
               "filter[before]" => "2026-03-09",
               "filter[person_id]" => "person-1",
               "filter[project_id]" => "project-1",
               "page" => "2",
               "per_page" => "200"
             }

      Req.Test.json(conn, %{"data" => [%{"id" => "entry-1"}], "links" => %{"next" => nil}})
    end)

    assert {:ok, %{"data" => [%{"id" => "entry-1"}], "links" => %{"next" => nil}}} =
             Productive.get_time_entries(client, %{
               project_id: "project-1",
               from: ~D[2026-03-01],
               to: ~D[2026-03-09],
               page: 2
             })
  end

  test "create_time_entry/2 posts JSON API body", %{client: client} do
    Req.Test.stub(Productive.Client, fn conn ->
      assert String.ends_with?(conn.request_path, "/time_entries")
      {:ok, body, conn} = Plug.Conn.read_body(conn)

      assert Jason.decode!(body) == %{
               "data" => %{
                 "type" => "time_entries",
                 "attributes" => %{
                   "date" => "2026-03-09",
                   "time" => 90,
                   "note" => ""
                 },
                 "relationships" => %{
                   "person" => %{
                     "data" => %{"type" => "people", "id" => "person-1"}
                   },
                   "service" => %{
                     "data" => %{"type" => "services", "id" => "service-1"}
                   }
                 }
               }
             }

      Req.Test.json(conn, %{"data" => %{"id" => "entry-1"}})
    end)

    assert {:ok, %{"data" => %{"id" => "entry-1"}}} =
             Productive.create_time_entry(client, %{
               date: ~D[2026-03-09],
               time: 90,
               note: "",
               service_id: "service-1"
             })
  end

  test "returns structured http errors", %{client: client} do
    Req.Test.stub(Productive.Client, fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("application/vnd.api+json")
      |> Plug.Conn.send_resp(422, Jason.encode!(%{"errors" => [%{"detail" => "Invalid"}]}))
    end)

    assert {:error,
            %Productive.Error{
              kind: :http_error,
              status: 422,
              body: %{"errors" => [%{"detail" => "Invalid"}]}
            }} = Productive.get_projects(client, 1)
  end

  test "returns structured validation errors before making a request", %{client: client} do
    assert {:error, %Productive.Error{kind: :validation_error, details: details}} =
             Productive.get_time_entries(client, %{
               project_id: "project-1",
               from: ~D[2026-03-09],
               to: ~D[2026-03-01],
               page: 0
             })

    assert details == %{page: "must be a positive integer"}
  end

  test "bang variants raise Productive.Error", %{client: client} do
    Req.Test.stub(Productive.Client, fn conn ->
      Req.Test.transport_error(conn, :timeout)
    end)

    assert_raise Productive.Error, ~r/timeout/, fn ->
      Productive.get_projects!(client, 1)
    end
  end

  test "returns transport errors", %{client: client} do
    Req.Test.stub(Productive.Client, fn conn ->
      Req.Test.transport_error(conn, :timeout)
    end)

    assert {:error,
            %Productive.Error{
              kind: :transport_error,
              details: %Req.TransportError{reason: :timeout}
            }} =
             Productive.get_projects(client, 1)
  end
end
