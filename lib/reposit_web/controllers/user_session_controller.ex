defmodule RepositWeb.UserSessionController do
  use RepositWeb, :controller

  alias Reposit.Accounts
  alias RepositWeb.UserAuth

  def new(conn, params) do
    email = get_in(conn.assigns, [:current_scope, Access.key(:user), Access.key(:email)])
    form = Phoenix.Component.to_form(%{"email" => email}, as: "user")

    conn
    |> maybe_store_return_to(params)
    |> render(:new, form: form)
  end

  defp maybe_store_return_to(conn, %{"return_to" => return_to})
       when is_binary(return_to) and return_to != "" do
    # Only allow relative paths to prevent open redirect vulnerabilities
    if String.starts_with?(return_to, "/") and not String.starts_with?(return_to, "//") do
      put_session(conn, :user_return_to, return_to)
    else
      conn
    end
  end

  defp maybe_store_return_to(conn, _params), do: conn

  # magic link login
  def create(conn, %{"user" => %{"token" => token} = user_params} = params) do
    info =
      case params do
        %{"_action" => "confirmed"} -> "User confirmed successfully."
        _ -> "Welcome back!"
      end

    case Accounts.login_user_by_magic_link(token) do
      {:ok, {user, _expired_tokens}} ->
        conn
        |> put_flash(:info, info)
        |> UserAuth.log_in_user(user, user_params)

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "The link is invalid or it has expired.")
        |> render(:new, form: Phoenix.Component.to_form(%{}, as: "user"))
    end
  end

  # magic link request - find or create user
  def create(conn, %{"user" => %{"email" => email} = user_params}) do
    # Honeypot: if the hidden field is filled, it's a bot - silently reject
    if honeypot_filled?(user_params) do
      conn
      |> put_flash(:info, "We've sent you a magic link to sign in. Check your email!")
      |> redirect(to: ~p"/users/log-in")
    else
      user = Accounts.get_user_by_email(email) || create_user(email)
      return_to = get_session(conn, :user_return_to)

      if user do
        Accounts.deliver_login_instructions(
          user,
          &magic_link_url(&1, return_to)
        )
      end

      conn
      |> put_flash(:info, "We've sent you a magic link to sign in. Check your email!")
      |> redirect(to: ~p"/users/log-in")
    end
  end

  defp magic_link_url(token, nil), do: url(~p"/users/log-in/#{token}")

  defp magic_link_url(token, return_to) do
    url(~p"/users/log-in/#{token}?return_to=#{return_to}")
  end

  defp honeypot_filled?(%{"website" => value}) when byte_size(value) > 0, do: true
  defp honeypot_filled?(_), do: false

  defp create_user(email) do
    case Accounts.register_user(%{email: email}) do
      {:ok, user} -> user
      {:error, _changeset} -> nil
    end
  end

  def confirm(conn, %{"token" => token} = params) do
    if user = Accounts.get_user_by_magic_link_token(token) do
      form = Phoenix.Component.to_form(%{"token" => token}, as: "user")

      conn
      |> maybe_store_return_to(params)
      |> assign(:user, user)
      |> assign(:form, form)
      |> render(:confirm)
    else
      conn
      |> put_flash(:error, "Magic link is invalid or it has expired.")
      |> redirect(to: ~p"/users/log-in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
