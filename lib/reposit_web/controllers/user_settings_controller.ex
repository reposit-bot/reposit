defmodule RepositWeb.UserSettingsController do
  use RepositWeb, :controller

  alias Reposit.Accounts

  import RepositWeb.UserAuth, only: [require_sudo_mode: 2]

  plug(:require_sudo_mode)
  plug(:assign_email_changeset)

  def edit(conn, _params) do
    render(conn, :edit)
  end

  def update(conn, %{"action" => "update_email"} = params) do
    %{"user" => user_params} = params
    user = conn.assigns.current_scope.user

    case Accounts.change_user_email(user, user_params) do
      %{valid?: true} = changeset ->
        Accounts.deliver_user_update_email_instructions(
          Ecto.Changeset.apply_action!(changeset, :insert),
          user.email,
          &url(~p"/users/settings/confirm-email/#{&1}")
        )

        conn
        |> put_flash(
          :info,
          "A link to confirm your email change has been sent to the new address."
        )
        |> redirect(to: ~p"/users/settings")

      changeset ->
        render(conn, :edit, email_changeset: %{changeset | action: :insert})
    end
  end

  def update(conn, %{"action" => "update_profile"} = params) do
    %{"user" => user_params} = params
    user = conn.assigns.current_scope.user

    case Accounts.update_user_profile(user, user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Profile updated successfully.")
        |> redirect(to: ~p"/users/settings")

      {:error, changeset} ->
        render(conn, :edit, profile_changeset: changeset)
    end
  end

  def confirm_email(conn, %{"token" => token}) do
    case Accounts.update_user_email(conn.assigns.current_scope.user, token) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Email changed successfully.")
        |> redirect(to: ~p"/users/settings")

      {:error, _} ->
        conn
        |> put_flash(:error, "Email change link is invalid or it has expired.")
        |> redirect(to: ~p"/users/settings")
    end
  end

  def create_api_token(conn, %{"name" => name}) do
    user = conn.assigns.current_scope.user

    case Accounts.create_api_token(user, name, :settings) do
      {:ok, token, _api_token} ->
        conn
        |> put_flash(:api_token, token)
        |> put_flash(:info, "API token created. Copy it now - it won't be shown again.")
        |> redirect(to: ~p"/users/settings")

      {:error, :token_limit_reached} ->
        conn
        |> put_flash(:error, "Token limit reached (50 max). Delete unused tokens first.")
        |> redirect(to: ~p"/users/settings")

      {:error, _} ->
        conn
        |> put_flash(:error, "Failed to create API token.")
        |> redirect(to: ~p"/users/settings")
    end
  end

  def delete_api_token(conn, %{"id" => id}) do
    user = conn.assigns.current_scope.user

    case Accounts.delete_api_token(user, id) do
      {:ok, :deleted} ->
        conn
        |> put_flash(:info, "API token deleted.")
        |> redirect(to: ~p"/users/settings")

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Token not found.")
        |> redirect(to: ~p"/users/settings")
    end
  end

  def delete(conn, _params) do
    user = conn.assigns.current_scope.user

    case Accounts.delete_user(user) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Account deleted successfully.")
        |> RepositWeb.UserAuth.log_out_user()

      {:error, _} ->
        conn
        |> put_flash(:error, "Failed to delete account.")
        |> redirect(to: ~p"/users/settings")
    end
  end

  def unlink_oauth(conn, %{"provider" => provider}) do
    user = conn.assigns.current_scope.user
    provider_atom = String.to_existing_atom(provider)
    provider_name = String.capitalize(provider)

    case Accounts.unlink_oauth_provider(user, provider_atom) do
      {:ok, _user} ->
        conn
        |> put_flash(
          :info,
          "#{provider_name} account disconnected. You can still sign in with email."
        )
        |> redirect(to: ~p"/users/settings")

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "Failed to disconnect #{provider_name} account.")
        |> redirect(to: ~p"/users/settings")
    end
  end

  defp assign_email_changeset(conn, _opts) do
    user = conn.assigns.current_scope.user

    conn
    |> assign(:email_changeset, Accounts.change_user_email(user))
    |> assign(:profile_changeset, Accounts.change_user_profile(user))
    |> assign(:api_tokens, Accounts.list_api_tokens(user))
  end
end
