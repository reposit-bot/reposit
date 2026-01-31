defmodule RepositWeb.AuthControllerTest do
  use RepositWeb.ConnCase, async: true

  import Reposit.AccountsFixtures

  describe "callback/2 with ueberauth_failure" do
    test "redirects to login with error for Google failure", %{conn: conn} do
      conn =
        conn
        |> assign(:ueberauth_failure, %Ueberauth.Failure{})
        |> get(~p"/auth/google/callback")

      assert redirected_to(conn) == ~p"/users/log-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Failed to authenticate with Google"
    end

    test "redirects to login with error for GitHub failure", %{conn: conn} do
      conn =
        conn
        |> assign(:ueberauth_failure, %Ueberauth.Failure{})
        |> get(~p"/auth/github/callback")

      assert redirected_to(conn) == ~p"/users/log-in"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "Failed to authenticate with Github"
    end
  end

  describe "callback/2 with ueberauth_auth" do
    test "creates new user and logs in for Google", %{conn: conn} do
      auth = build_ueberauth_auth(:google, "google_new_123", "newuser@example.com", "New User")

      conn =
        conn
        |> assign(:ueberauth_auth, auth)
        |> get(~p"/auth/google/callback")

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome"
    end

    test "creates new user and logs in for GitHub", %{conn: conn} do
      auth = build_ueberauth_auth(:github, "github_new_123", "newuser@example.com", "New User")

      conn =
        conn
        |> assign(:ueberauth_auth, auth)
        |> get(~p"/auth/github/callback")

      assert redirected_to(conn) == ~p"/"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Welcome"
    end

    test "logs in existing user for Google", %{conn: conn} do
      existing_user = user_fixture()

      existing_user
      |> Ecto.Changeset.change(google_uid: "google_existing_123")
      |> Reposit.Repo.update!()

      auth =
        build_ueberauth_auth(
          :google,
          "google_existing_123",
          existing_user.email,
          "Existing User"
        )

      conn =
        conn
        |> assign(:ueberauth_auth, auth)
        |> get(~p"/auth/google/callback")

      assert redirected_to(conn) == ~p"/"
    end

    test "logs in existing user for GitHub", %{conn: conn} do
      existing_user = user_fixture()

      existing_user
      |> Ecto.Changeset.change(github_uid: "github_existing_123")
      |> Reposit.Repo.update!()

      auth =
        build_ueberauth_auth(
          :github,
          "github_existing_123",
          existing_user.email,
          "Existing User"
        )

      conn =
        conn
        |> assign(:ueberauth_auth, auth)
        |> get(~p"/auth/github/callback")

      assert redirected_to(conn) == ~p"/"
    end

    test "links Google account to existing user with same email", %{conn: conn} do
      existing_user = user_fixture()

      auth =
        build_ueberauth_auth(:google, "google_link_123", existing_user.email, "Link User")

      conn =
        conn
        |> assign(:ueberauth_auth, auth)
        |> get(~p"/auth/google/callback")

      assert redirected_to(conn) == ~p"/"

      # Verify the account was linked
      updated_user = Reposit.Accounts.get_user!(existing_user.id)
      assert updated_user.google_uid == "google_link_123"
    end
  end

  describe "callback/2 when user is already logged in (account linking)" do
    setup :register_and_log_in_user

    test "links Google account to logged-in user", %{conn: conn, user: user} do
      auth =
        build_ueberauth_auth(:google, "google_link_new", "different@example.com", "OAuth Name")

      conn =
        conn
        |> assign(:ueberauth_auth, auth)
        |> get(~p"/auth/google/callback")

      assert redirected_to(conn) == ~p"/users/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "Google account connected"

      updated_user = Reposit.Accounts.get_user!(user.id)
      assert updated_user.google_uid == "google_link_new"
    end

    test "links GitHub account to logged-in user", %{conn: conn, user: user} do
      auth =
        build_ueberauth_auth(:github, "github_link_new", "different@example.com", "OAuth Name")

      conn =
        conn
        |> assign(:ueberauth_auth, auth)
        |> get(~p"/auth/github/callback")

      assert redirected_to(conn) == ~p"/users/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :info) =~ "account connected"

      updated_user = Reposit.Accounts.get_user!(user.id)
      assert updated_user.github_uid == "github_link_new"
    end

    test "shows error when OAuth account is already linked to another user", %{conn: conn} do
      # Create another user with Google linked
      other_user = user_fixture()

      other_user
      |> Ecto.Changeset.change(google_uid: "google_taken")
      |> Reposit.Repo.update!()

      # Try to link the same Google account to logged-in user
      auth = build_ueberauth_auth(:google, "google_taken", "other@example.com", "Other User")

      conn =
        conn
        |> assign(:ueberauth_auth, auth)
        |> get(~p"/auth/google/callback")

      assert redirected_to(conn) == ~p"/users/settings"
      assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "already linked to another user"
    end
  end

  defp build_ueberauth_auth(provider, uid, email, name) do
    %Ueberauth.Auth{
      uid: uid,
      provider: provider,
      info: %Ueberauth.Auth.Info{
        email: email,
        name: name,
        image: "https://example.com/avatar.jpg"
      }
    }
  end
end
