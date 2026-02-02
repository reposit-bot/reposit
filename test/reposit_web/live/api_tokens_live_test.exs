defmodule RepositWeb.ApiTokensLiveTest do
  use RepositWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Reposit.Accounts

  describe "ApiTokensLive" do
    setup :register_and_log_in_user

    test "redirects to log-in when not authenticated", %{conn: _conn} do
      conn = build_conn()
      {:error, {:redirect, %{to: to}}} = live(conn, ~p"/users/api-tokens")
      assert to == ~p"/users/log-in"
    end

    test "renders API Tokens page when authenticated", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/users/api-tokens")

      assert has_element?(view, "h1", "API Tokens")
      assert has_element?(view, "#create-token-form")
      assert render(view) =~ "Create Token"
      assert render(view) =~ "No API tokens yet"
      assert render(view) =~ "0 / 50 tokens used"
    end

    test "creates a new API token and shows copy-once alert", %{conn: conn, user: user} do
      {:ok, view, _html} = live(conn, ~p"/users/api-tokens")

      view
      |> form("#create-token-form", %{name: "My Laptop"})
      |> render_submit()

      assert render(view) =~ "Copy your token now"
      assert render(view) =~ "Dismiss"
      assert has_element?(view, "code")

      tokens = Accounts.list_api_tokens(user)
      assert length(tokens) == 1
      assert hd(tokens).name == "My Laptop"
      assert hd(tokens).source == :settings
    end

    test "clear_new_token dismisses the copy-once alert", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/users/api-tokens")

      view
      |> form("#create-token-form", %{name: "Test Token"})
      |> render_submit()

      assert render(view) =~ "Copy your token now"

      view |> element("button", "Dismiss") |> render_click()

      refute render(view) =~ "Copy your token now"
    end

    test "create with empty name shows error", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/users/api-tokens")

      view
      |> form("#create-token-form", %{name: "   "})
      |> render_submit()

      assert has_element?(view, "#flash-error", "Token name can't be blank")
    end

    test "create when token limit reached shows error", %{conn: conn, user: user} do
      for i <- 1..50 do
        {:ok, _, _} = Accounts.create_api_token(user, "Token #{i}", :settings)
      end

      {:ok, view, _html} = live(conn, ~p"/users/api-tokens")

      view
      |> form("#create-token-form", %{name: "Token 51"})
      |> render_submit()

      assert render(view) =~ "Token limit reached"
    end

    test "delete removes token", %{conn: conn, user: user} do
      {:ok, _, api_token} = Accounts.create_api_token(user, "To Delete", :settings)

      {:ok, view, _html} = live(conn, ~p"/users/api-tokens")

      assert render(view) =~ "To Delete"

      # data-confirm triggers browser confirm; in tests we need to pass confirm option
      view
      |> element("button[phx-click='delete'][phx-value-id='#{api_token.id}']")
      |> render_click()

      refute render(view) =~ "To Delete"
      assert Accounts.count_api_tokens(user) == 0
    end

    test "rename updates token name", %{conn: conn, user: user} do
      {:ok, _, api_token} = Accounts.create_api_token(user, "Old Name", :settings)

      {:ok, view, _html} = live(conn, ~p"/users/api-tokens")

      assert render(view) =~ "Old Name"

      view |> element("button[phx-click='edit_rename']", "Rename") |> render_click()

      assert has_element?(view, "form#rename-form-#{api_token.id}")

      view
      |> form("form#rename-form-#{api_token.id}", %{token_id: api_token.id, name: "New Name"})
      |> render_submit()

      assert render(view) =~ "New Name"
      refute render(view) =~ "Old Name"

      tokens = Accounts.list_api_tokens(user)
      assert hd(tokens).name == "New Name"
    end

    test "cancel_rename clears edit mode", %{conn: conn, user: user} do
      {:ok, _, api_token} = Accounts.create_api_token(user, "My Token", :settings)

      {:ok, view, _html} = live(conn, ~p"/users/api-tokens")

      view |> element("button[phx-click='edit_rename']", "Rename") |> render_click()
      assert has_element?(view, "form#rename-form-#{api_token.id}")

      view |> element("button", "Cancel") |> render_click()
      refute has_element?(view, "form#rename-form-#{api_token.id}")
      assert render(view) =~ "My Token"
    end

    test "rename with empty name shows error", %{conn: conn, user: user} do
      {:ok, _, api_token} = Accounts.create_api_token(user, "My Token", :settings)

      {:ok, view, _html} = live(conn, ~p"/users/api-tokens")

      view |> element("button[phx-click='edit_rename']", "Rename") |> render_click()

      view
      |> form("form#rename-form-#{api_token.id}", %{token_id: api_token.id, name: "   "})
      |> render_submit()

      assert has_element?(view, "#flash-error", "Token name can't be blank")
      # Token name unchanged
      tokens = Accounts.list_api_tokens(user)
      assert hd(tokens).name == "My Token"
    end
  end
end
