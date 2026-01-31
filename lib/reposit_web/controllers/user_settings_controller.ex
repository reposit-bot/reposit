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

  def regenerate_api_token(conn, _params) do
    user = conn.assigns.current_scope.user

    case Accounts.regenerate_api_token(user) do
      {:ok, token, _user} ->
        conn
        |> put_flash(:api_token, token)
        |> put_flash(:info, "API token regenerated. Copy it now - it won't be shown again.")
        |> redirect(to: ~p"/users/settings")

      {:error, _} ->
        conn
        |> put_flash(:error, "Failed to regenerate API token.")
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

  defp assign_email_changeset(conn, _opts) do
    user = conn.assigns.current_scope.user

    conn
    |> assign(:email_changeset, Accounts.change_user_email(user))
  end
end
