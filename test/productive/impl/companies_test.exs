defmodule Productive.Impl.CompaniesTest do
  use ExUnit.Case, async: false

  setup do
    Application.put_env(:productive, :req_options,
      plug: {Req.Test, Productive.Client},
      retry: false
    )

    on_exit(fn -> Application.delete_env(:productive, :req_options) end)

    client =
      Productive.Client.new!(%{
        auth_token: "productive-token",
        person_id: "person-1",
        organization_id: "org-1"
      })

    %{client: client}
  end

  test "get_companies/2 hits /companies with pagination", %{client: client} do
    Req.Test.stub(Productive.Client, fn conn ->
      assert String.ends_with?(conn.request_path, "/companies")

      assert URI.decode_query(conn.query_string) == %{"page" => "2", "per_page" => "50"}

      Req.Test.json(conn, %{"data" => [%{"id" => "co-1"}]})
    end)

    assert {:ok, %{"data" => [%{"id" => "co-1"}]}} = Productive.get_companies(client, %{page: 2})
  end

  test "get_company/2 hits /companies/:id", %{client: client} do
    Req.Test.stub(Productive.Client, fn conn ->
      assert String.ends_with?(conn.request_path, "/companies/co-42")
      Req.Test.json(conn, %{"data" => %{"id" => "co-42"}})
    end)

    assert {:ok, %{"data" => %{"id" => "co-42"}}} = Productive.get_company(client, "co-42")
  end

  test "get_companies/2 rejects bad page", %{client: client} do
    assert {:error, %Productive.Error{kind: :validation_error}} =
             Productive.get_companies(client, %{page: 0})
  end
end
