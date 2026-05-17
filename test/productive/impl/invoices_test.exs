defmodule Productive.Impl.InvoicesTest do
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

  test "get_invoices/2 hits /invoices with paging and include params", %{client: client} do
    Req.Test.stub(Productive.Client, fn conn ->
      assert String.ends_with?(conn.request_path, "/invoices")

      assert URI.decode_query(conn.query_string) == %{
               "include" => "line_items,bill_from",
               "page" => "1",
               "per_page" => "50"
             }

      Req.Test.json(conn, %{"data" => [%{"id" => "inv-1"}], "links" => %{"next" => nil}})
    end)

    assert {:ok, %{"data" => [%{"id" => "inv-1"}]}} = Productive.get_invoices(client, %{page: 1})
  end

  test "get_invoices/2 encodes filter[after] from a DateTime", %{client: client} do
    Req.Test.stub(Productive.Client, fn conn ->
      assert URI.decode_query(conn.query_string)["filter[after]"] == "2026-05-16T10:00:00Z"
      Req.Test.json(conn, %{"data" => []})
    end)

    assert {:ok, _} =
             Productive.get_invoices(client, %{
               page: 1,
               after: ~U[2026-05-16 10:00:00Z]
             })
  end

  test "get_invoice/2 hits /invoices/:id", %{client: client} do
    Req.Test.stub(Productive.Client, fn conn ->
      assert String.ends_with?(conn.request_path, "/invoices/inv-42")
      Req.Test.json(conn, %{"data" => %{"id" => "inv-42"}})
    end)

    assert {:ok, %{"data" => %{"id" => "inv-42"}}} = Productive.get_invoice(client, "inv-42")
  end

  test "get_invoices/2 rejects bad page", %{client: client} do
    assert {:error, %Productive.Error{kind: :validation_error}} =
             Productive.get_invoices(client, %{page: 0})
  end
end
