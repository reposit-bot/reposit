defmodule ChorusWeb.Plugs.ApiAuth do
  @moduledoc """
  Plug for authenticating API requests using API tokens.

  Extracts the token from the Authorization header (Bearer scheme) or
  the `api_token` query parameter. Validates the token and assigns
  the user to the connection.

  Returns 401 Unauthorized for invalid or missing tokens.
  """
  import Plug.Conn

  alias Chorus.Accounts

  @behaviour Plug

  @impl true
  def init(opts), do: opts

  @impl true
  def call(conn, _opts) do
    with {:ok, token} <- extract_token(conn),
         %Accounts.User{} = user <- Accounts.get_user_by_api_token(token) do
      assign(conn, :current_user, user)
    else
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          401,
          Jason.encode!(%{
            success: false,
            error: "unauthorized",
            hint: "Invalid or missing API token. Get your token from /users/settings"
          })
        )
        |> halt()
    end
  end

  defp extract_token(conn) do
    case get_req_header(conn, "authorization") do
      ["Bearer " <> token] ->
        {:ok, String.trim(token)}

      _ ->
        conn = Plug.Conn.fetch_query_params(conn)

        case conn.query_params["api_token"] do
          nil -> :error
          token -> {:ok, token}
        end
    end
  end
end
