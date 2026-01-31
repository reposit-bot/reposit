defmodule RepositWeb.AuthController do
  @moduledoc """
  Handles OAuth authentication callbacks from Ueberauth providers (Google, GitHub).
  """
  use RepositWeb, :controller

  plug Ueberauth

  alias Reposit.Accounts
  alias RepositWeb.UserAuth

  @doc """
  Handles the OAuth callback from providers.
  On success, logs the user in. On failure, redirects to login with an error.
  """
  def callback(conn, params)

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, %{"provider" => provider}) do
    user_info = extract_user_info(auth)

    result =
      case provider do
        "google" -> Accounts.get_or_create_user_from_google(user_info)
        "github" -> Accounts.get_or_create_user_from_github(user_info)
      end

    case result do
      {:ok, user} ->
        conn
        |> put_flash(:info, welcome_message(user))
        |> UserAuth.log_in_user(user)

      {:error, _changeset} ->
        conn
        |> put_flash(:error, "There was a problem signing in. Please try again.")
        |> redirect(to: ~p"/users/log-in")
    end
  end

  def callback(%{assigns: %{ueberauth_failure: _failure}} = conn, %{"provider" => provider}) do
    provider_name = String.capitalize(provider)

    conn
    |> put_flash(
      :error,
      "Failed to authenticate with #{provider_name}. Please try again or use email sign-in."
    )
    |> redirect(to: ~p"/users/log-in")
  end

  defp extract_user_info(auth) do
    %{
      email: auth.info.email,
      uid: auth.uid,
      name: auth.info.name,
      avatar_url: auth.info.image
    }
  end

  defp welcome_message(user) do
    if user.name do
      "Welcome, #{user.name}!"
    else
      "Welcome!"
    end
  end
end
