defmodule ChorusWeb.Plugs.ApiAuthTest do
  use ChorusWeb.ConnCase, async: true

  alias ChorusWeb.Plugs.ApiAuth

  import Chorus.AccountsFixtures

  describe "call/2" do
    test "assigns current_user with valid Bearer token", %{conn: conn} do
      user = user_fixture()
      {:ok, token, _user} = Chorus.Accounts.generate_api_token(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> ApiAuth.call([])

      assert conn.assigns.current_user.id == user.id
      refute conn.halted
    end

    test "assigns current_user with valid query param token", %{conn: conn} do
      user = user_fixture()
      {:ok, token, _user} = Chorus.Accounts.generate_api_token(user)

      conn =
        conn
        |> Map.put(:query_params, %{"api_token" => token})
        |> ApiAuth.call([])

      assert conn.assigns.current_user.id == user.id
      refute conn.halted
    end

    test "returns 401 for missing token", %{conn: conn} do
      conn = ApiAuth.call(conn, [])

      assert conn.halted
      assert conn.status == 401
      assert Jason.decode!(conn.resp_body)["error"] == "unauthorized"
    end

    test "returns 401 for invalid token", %{conn: conn} do
      conn =
        conn
        |> put_req_header("authorization", "Bearer invalid-token")
        |> ApiAuth.call([])

      assert conn.halted
      assert conn.status == 401
    end

    test "returns 401 for unconfirmed user", %{conn: conn} do
      user = unconfirmed_user_fixture()
      {:ok, token, _user} = Chorus.Accounts.generate_api_token(user)

      conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> ApiAuth.call([])

      assert conn.halted
      assert conn.status == 401
    end
  end
end
