defmodule RepositWeb.Api.V1.DeviceAuthController do
  @moduledoc """
  API controller for device code authentication flow.

  This enables CLI tools and MCP servers to authenticate without
  direct browser access using the OAuth 2.0 Device Authorization Grant flow.
  """
  use RepositWeb, :controller

  alias Reposit.Accounts

  @doc """
  Starts a device authorization flow.

  POST /api/v1/auth/device

  Request body:
    - backend_url: The URL of the Reposit backend (for multi-backend support)

  Response:
    - device_code: The code for the client to poll with
    - user_code: The code for the user to enter
    - verification_url: Where the user should go to enter the code
    - expires_in: Seconds until expiration
    - interval: Recommended polling interval in seconds
  """
  def create(conn, params) do
    backend_url = Map.get(params, "backend_url", default_backend_url(conn))

    case Accounts.create_device_code(backend_url) do
      {:ok, device_code_info} ->
        verification_url = url(~p"/auth/device")

        json(conn, %{
          success: true,
          data: %{
            device_code: device_code_info.device_code,
            user_code: device_code_info.user_code,
            verification_url: verification_url,
            expires_in: device_code_info.expires_in,
            interval: 5
          }
        })

      {:error, _changeset} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{
          success: false,
          error: "device_code_creation_failed",
          hint: "Failed to create device code. Please try again."
        })
    end
  end

  @doc """
  Polls for device code completion.

  POST /api/v1/auth/device/poll

  Request body:
    - device_code: The device code returned from the create endpoint
    - device_name: (optional) A friendly name for this device (e.g., "MacBook Pro", "Claude Desktop")

  Response (pending):
    - status: "pending"

  Response (complete):
    - status: "complete"
    - token: The API token to use for authenticated requests

  Response (error):
    - error: "expired" | "not_found" | "token_limit_reached"
  """
  def poll(conn, %{"device_code" => device_code} = params) do
    device_name = Map.get(params, "device_name")
    opts = if device_name, do: [device_name: device_name], else: []

    case Accounts.poll_device_code(device_code, opts) do
      {:ok, :pending} ->
        json(conn, %{
          success: true,
          data: %{status: "pending"}
        })

      {:ok, token} ->
        json(conn, %{
          success: true,
          data: %{
            status: "complete",
            token: token
          }
        })

      {:error, :not_found} ->
        # Also covers expired codes (they're filtered out by the query)
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: "not_found",
          hint: "Invalid or expired device code."
        })

      {:error, :token_limit_reached} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: "token_limit_reached",
          hint:
            "You have reached the maximum number of API tokens (50). Please delete unused tokens in settings."
        })

      {:error, :token_generation_failed} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{
          success: false,
          error: "token_generation_failed",
          hint: "Failed to generate API token. Please try again."
        })
    end
  end

  def poll(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{
      success: false,
      error: "missing_device_code",
      hint: "The device_code parameter is required."
    })
  end

  defp default_backend_url(conn) do
    "#{conn.scheme}://#{conn.host}#{if conn.port in [80, 443], do: "", else: ":#{conn.port}"}"
  end
end
