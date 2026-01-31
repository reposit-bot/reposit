defmodule RepositWeb.Api.V1.HealthControllerTest do
  use RepositWeb.ConnCase

  describe "GET /api/v1/health" do
    test "returns success with status ok", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/health")

      assert json_response(conn, 200) == %{
               "success" => true,
               "data" => %{"status" => "ok"}
             }
    end
  end
end
