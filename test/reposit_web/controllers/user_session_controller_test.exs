defmodule RepositWeb.UserSessionControllerTest do
  use RepositWeb.ConnCase, async: true

  import Reposit.AccountsFixtures
  alias Reposit.Accounts

  setup do
    %{unconfirmed_user: unconfirmed_user_fixture(), user: user_fixture()}
  end

  describe "GET /users/log-in" do
    test "renders login page", %{conn: conn} do
      conn = get(conn, ~p"/users/log-in")
      response = html_response(conn, 200)
      assert response =~ "Sign in"
      assert response =~ "Send sign-in link"
    end

    test "renders login page with email filled in (sudo mode)", %{conn: conn, user: user} do
      html =
        conn
        |> log_in_user(user)
        |> get(~p"/users/log-in")
        |> html_response(200)

      assert html =~ "You need to reauthenticate"
      assert html =~ "Send sign-in link"

      assert html =~
               ~s(<input type="email" name="user[email]" id="login_form_magic_email" value="#{user.email}")
    end
  end

  describe "GET /users/log-in/:token" do
    test "renders confirmation page for unconfirmed user", %{conn: conn, unconfirmed_user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_login_instructions(user, url)
        end)

      conn = get(conn, ~p"/users/log-in/#{token}")
      assert html_response(conn, 200) =~ "Confirm and stay signed in"
    end

    test "renders login page for confirmed user", %{conn: conn, user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_login_instructions(user, url)
        end)

      conn = get(conn, ~p"/users/log-in/#{token}")
      html = html_response(conn, 200)
      refute html =~ "Confirm my account"
      assert html =~ "Sign in"
    end

    test "raises error for invalid token", %{conn: conn} do
      conn = get(conn, ~p"/users/log-in/invalid-token")
      assert redirected_to(conn) == ~p"/users/log-in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "Magic link is invalid or it has expired."
    end
  end

  describe "POST /users/log-in - magic link" do
    test "sends magic link email when user exists", %{conn: conn, user: user} do
      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{"email" => user.email}
        })

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "If your email is in our system"
      assert Reposit.Repo.get_by!(Accounts.UserToken, user_id: user.id).context == "login"
    end

    test "logs the user in", %{conn: conn, user: user} do
      {token, _hashed_token} = generate_user_magic_link_token(user)

      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{"token" => token}
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ user.email
      assert response =~ ~p"/users/settings"
      assert response =~ ~p"/users/log-out"
    end

    test "confirms unconfirmed user", %{conn: conn, unconfirmed_user: user} do
      {token, _hashed_token} = generate_user_magic_link_token(user)
      refute user.confirmed_at

      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{"token" => token},
          "_action" => "confirmed"
        })

      assert get_session(conn, :user_token)
      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "User confirmed successfully."

      assert Accounts.get_user!(user.id).confirmed_at

      # Now do a logged in request and assert on the menu
      conn = get(conn, ~p"/")
      response = html_response(conn, 200)
      assert response =~ user.email
      assert response =~ ~p"/users/settings"
      assert response =~ ~p"/users/log-out"
    end

    test "emits error message when magic link is invalid", %{conn: conn} do
      conn =
        post(conn, ~p"/users/log-in", %{
          "user" => %{"token" => "invalid"}
        })

      assert html_response(conn, 200) =~ "The link is invalid or it has expired."
    end
  end

  describe "DELETE /users/log-out" do
    test "logs the user out", %{conn: conn, user: user} do
      conn = conn |> log_in_user(user) |> delete(~p"/users/log-out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end

    test "succeeds even if the user is not logged in", %{conn: conn} do
      conn = delete(conn, ~p"/users/log-out")
      assert redirected_to(conn) == ~p"/"
      refute get_session(conn, :user_token)
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Logged out successfully"
    end
  end
end
