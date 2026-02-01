defmodule RepositWeb.UserSettingsControllerTest do
  use RepositWeb.ConnCase, async: true

  alias Reposit.Accounts
  import Reposit.AccountsFixtures

  setup :register_and_log_in_user

  describe "GET /users/settings" do
    test "renders settings page", %{conn: conn} do
      conn = get(conn, ~p"/users/settings")
      response = html_response(conn, 200)
      assert response =~ "Settings"
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = get(conn, ~p"/users/settings")
      assert redirected_to(conn) == ~p"/users/log-in"
    end

    @tag token_authenticated_at: DateTime.add(DateTime.utc_now(:second), -61, :minute)
    test "redirects if user is not in sudo mode", %{conn: conn} do
      conn = get(conn, ~p"/users/settings")
      assert redirected_to(conn) == ~p"/users/log-in"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) ==
               "You must re-authenticate to access this page."
    end
  end

  describe "PUT /users/settings (change email form)" do
    @tag :capture_log
    test "updates the user email", %{conn: conn, user: user} do
      conn =
        put(conn, ~p"/users/settings", %{
          "action" => "update_email",
          "user" => %{"email" => unique_user_email()}
        })

      assert redirected_to(conn) == ~p"/users/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "A link to confirm your email"

      assert Accounts.get_user_by_email(user.email)
    end

    test "does not update email on invalid data", %{conn: conn} do
      conn =
        put(conn, ~p"/users/settings", %{
          "action" => "update_email",
          "user" => %{"email" => "with spaces"}
        })

      response = html_response(conn, 200)
      assert response =~ "Settings"
      assert response =~ "must have the @ sign and no spaces"
    end
  end

  describe "GET /users/settings/confirm-email/:token" do
    setup %{user: user} do
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{token: token, email: email}
    end

    test "updates the user email once", %{conn: conn, user: user, token: token, email: email} do
      conn = get(conn, ~p"/users/settings/confirm-email/#{token}")
      assert redirected_to(conn) == ~p"/users/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Email changed successfully"

      refute Accounts.get_user_by_email(user.email)
      assert Accounts.get_user_by_email(email)

      conn = get(conn, ~p"/users/settings/confirm-email/#{token}")

      assert redirected_to(conn) == ~p"/users/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Email change link is invalid or it has expired"
    end

    test "does not update email with invalid token", %{conn: conn, user: user} do
      conn = get(conn, ~p"/users/settings/confirm-email/oops")
      assert redirected_to(conn) == ~p"/users/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~
               "Email change link is invalid or it has expired"

      assert Accounts.get_user_by_email(user.email)
    end

    test "redirects if user is not logged in", %{token: token} do
      conn = build_conn()
      conn = get(conn, ~p"/users/settings/confirm-email/#{token}")
      assert redirected_to(conn) == ~p"/users/log-in"
    end
  end

  describe "PUT /users/settings (update profile form)" do
    test "updates the user profile", %{conn: conn} do
      conn =
        put(conn, ~p"/users/settings", %{
          "action" => "update_profile",
          "user" => %{"name" => "Test User"}
        })

      assert redirected_to(conn) == ~p"/users/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Profile updated successfully"
    end

    test "allows empty name", %{conn: conn} do
      conn =
        put(conn, ~p"/users/settings", %{
          "action" => "update_profile",
          "user" => %{"name" => ""}
        })

      assert redirected_to(conn) == ~p"/users/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Profile updated successfully"
    end
  end

  describe "DELETE /users/settings/oauth/:provider" do
    test "unlinks Google OAuth provider", %{conn: conn, user: user} do
      # Link Google first
      user
      |> Ecto.Changeset.change(google_uid: "google_123")
      |> Reposit.Repo.update!()

      conn = delete(conn, ~p"/users/settings/oauth/google")
      assert redirected_to(conn) == ~p"/users/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Google account disconnected"

      updated_user = Accounts.get_user!(user.id)
      assert is_nil(updated_user.google_uid)
    end

    test "unlinks GitHub OAuth provider", %{conn: conn, user: user} do
      # Link GitHub first
      user
      |> Ecto.Changeset.change(github_uid: "github_123")
      |> Reposit.Repo.update!()

      conn = delete(conn, ~p"/users/settings/oauth/github")
      assert redirected_to(conn) == ~p"/users/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "account disconnected"

      updated_user = Accounts.get_user!(user.id)
      assert is_nil(updated_user.github_uid)
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = delete(conn, ~p"/users/settings/oauth/google")
      assert redirected_to(conn) == ~p"/users/log-in"
    end
  end

  describe "POST /users/settings/api-tokens" do
    test "creates a new API token", %{conn: conn, user: user} do
      conn = post(conn, ~p"/users/settings/api-tokens", %{name: "My New Token"})
      assert redirected_to(conn) == ~p"/users/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "API token created"
      assert Phoenix.Flash.get(conn.assigns.flash, :api_token)

      # Token should be in the list
      tokens = Accounts.list_api_tokens(user)
      assert length(tokens) == 1
      assert hd(tokens).name == "My New Token"
      assert hd(tokens).source == :settings
    end

    test "returns error when token limit reached", %{conn: conn, user: user} do
      # Create 50 tokens
      for i <- 1..50 do
        {:ok, _, _} = Accounts.create_api_token(user, "Token #{i}", :settings)
      end

      conn = post(conn, ~p"/users/settings/api-tokens", %{name: "Token 51"})
      assert redirected_to(conn) == ~p"/users/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Token limit reached"
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = post(conn, ~p"/users/settings/api-tokens", %{name: "Test"})
      assert redirected_to(conn) == ~p"/users/log-in"
    end
  end

  describe "DELETE /users/settings/api-tokens/:id" do
    test "deletes an API token", %{conn: conn, user: user} do
      {:ok, _, api_token} = Accounts.create_api_token(user, "To Delete", :settings)

      conn = delete(conn, ~p"/users/settings/api-tokens/#{api_token.id}")
      assert redirected_to(conn) == ~p"/users/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "API token deleted"
      assert Accounts.count_api_tokens(user) == 0
    end

    test "returns error for non-existent token", %{conn: conn} do
      conn = delete(conn, ~p"/users/settings/api-tokens/999999")
      assert redirected_to(conn) == ~p"/users/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Token not found"
    end

    test "cannot delete another user's token", %{conn: conn} do
      other_user = user_fixture()
      {:ok, _, api_token} = Accounts.create_api_token(other_user, "Other User Token", :settings)

      conn = delete(conn, ~p"/users/settings/api-tokens/#{api_token.id}")
      assert redirected_to(conn) == ~p"/users/settings"

      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Token not found"
      # Token still exists
      assert Accounts.count_api_tokens(other_user) == 1
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = delete(conn, ~p"/users/settings/api-tokens/123")
      assert redirected_to(conn) == ~p"/users/log-in"
    end
  end

  describe "DELETE /users/settings" do
    test "deletes the user account and logs out", %{conn: conn, user: user} do
      conn = delete(conn, ~p"/users/settings")
      assert redirected_to(conn) == ~p"/"

      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~
               "Account deleted successfully"

      refute Accounts.get_user_by_email(user.email)
    end

    test "redirects if user is not logged in" do
      conn = build_conn()
      conn = delete(conn, ~p"/users/settings")
      assert redirected_to(conn) == ~p"/users/log-in"
    end
  end
end
