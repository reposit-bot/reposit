defmodule RepositWeb.UserRegistrationControllerTest do
  use RepositWeb.ConnCase, async: true

  import Reposit.AccountsFixtures

  describe "GET /users/register" do
    test "redirects to login page", %{conn: conn} do
      conn = get(conn, ~p"/users/register")
      assert redirected_to(conn) == ~p"/users/log-in"
    end

    test "redirects to login even if already logged in", %{conn: conn} do
      conn = conn |> log_in_user(user_fixture()) |> get(~p"/users/register")
      assert redirected_to(conn) == ~p"/users/log-in"
    end
  end
end
