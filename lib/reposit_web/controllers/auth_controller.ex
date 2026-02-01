defmodule RepositWeb.AuthController do
  @moduledoc """
  Handles OAuth authentication callbacks from Ueberauth providers (Google, GitHub).

  Supports three flows:
  1. Sign in/up: User is not logged in, OAuth creates or finds their account
  2. Sudo re-auth: User is logged in with provider linked, re-authenticating refreshes session
  3. Account linking: User is logged in without provider linked, OAuth links it to their account
  """
  use RepositWeb, :controller

  plug Ueberauth

  alias Reposit.Accounts
  alias RepositWeb.UserAuth

  @doc """
  Handles the OAuth callback from providers.
  On success, logs the user in (or links account if already logged in).
  On failure, redirects with an error.
  """
  def callback(conn, params)

  def callback(%{assigns: %{ueberauth_auth: auth, current_scope: %{user: user}}} = conn, %{
        "provider" => provider
      })
      when not is_nil(user) do
    user_info = extract_user_info(auth)
    provider_name = String.capitalize(provider)

    # Check if this is sudo re-auth (provider already linked) or account linking
    user_provider_uid = get_user_provider_uid(user, provider)

    cond do
      # Sudo re-auth: provider is linked and UIDs match - refresh session
      user_provider_uid == user_info.uid ->
        conn
        |> UserAuth.log_in_user(user)

      # Provider not linked yet - link it
      is_nil(user_provider_uid) ->
        link_provider_account(conn, user, user_info, provider, provider_name)

      # Provider linked but UID doesn't match - wrong account
      true ->
        conn
        |> put_flash(
          :error,
          "Please sign in with the same #{provider_name} account that's linked to your profile."
        )
        |> redirect(to: ~p"/users/log-in")
    end
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, %{"provider" => provider}) do
    # User is not logged in - sign in or create account
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

  defp link_provider_account(conn, user, user_info, provider, provider_name) do
    result =
      case provider do
        "google" -> Accounts.link_google_account(user, user_info)
        "github" -> Accounts.link_github_account(user, user_info)
      end

    case result do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "#{provider_name} account connected successfully!")
        |> redirect(to: ~p"/users/settings")

      {:error, changeset} ->
        error_message = link_error_message(changeset, provider_name)

        conn
        |> put_flash(:error, error_message)
        |> redirect(to: ~p"/users/settings")
    end
  end

  defp get_user_provider_uid(user, "google"), do: user.google_uid
  defp get_user_provider_uid(user, "github"), do: user.github_uid

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

  defp link_error_message(changeset, provider_name) do
    cond do
      Keyword.has_key?(changeset.errors, :google_uid) or
          Keyword.has_key?(changeset.errors, :github_uid) ->
        "This #{provider_name} account is already linked to another user."

      true ->
        "Failed to connect #{provider_name} account. Please try again."
    end
  end
end
