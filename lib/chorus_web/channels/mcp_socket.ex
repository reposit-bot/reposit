defmodule ChorusWeb.McpSocket do
  @moduledoc """
  Socket handler for MCP (Model Context Protocol) connections.

  Handles WebSocket connections at `/mcp` endpoint for Claude Code
  and other MCP-compatible clients.

  ## Authentication

  Authentication is optional and configurable:
  - When `:mcp_auth` is disabled, all connections are accepted
  - When enabled, valid tokens are required for authenticated access
  - Empty/missing tokens allow unauthenticated (public) access
  - Invalid tokens are rejected

  Configure in your environment:

      config :chorus, :mcp_auth,
        enabled: true,
        tokens: ["token1", "token2"]

  """
  use Phoenix.Socket

  channel "mcp:*", ChorusWeb.McpChannel

  @impl true
  def connect(params, socket, _connect_info) do
    token = Map.get(params, "token")
    auth_config = Application.get_env(:chorus, :mcp_auth, [])

    case authenticate(token, auth_config) do
      {:ok, auth_state} ->
        socket =
          socket
          |> maybe_assign_token(token)
          |> maybe_assign_authenticated(auth_state)

        {:ok, socket}

      :error ->
        :error
    end
  end

  @impl true
  def id(_socket), do: nil

  # Authentication logic

  defp authenticate(token, config) do
    enabled = Keyword.get(config, :enabled, false)
    valid_tokens = Keyword.get(config, :tokens, [])

    cond do
      # No token provided - allow unauthenticated access
      is_nil(token) or token == "" ->
        {:ok, :unauthenticated}

      # Auth disabled - accept any token
      not enabled ->
        {:ok, :unauthenticated}

      # Valid token
      token in valid_tokens ->
        {:ok, :authenticated}

      # Invalid token when auth is enabled
      true ->
        :error
    end
  end

  defp maybe_assign_token(socket, nil), do: socket
  defp maybe_assign_token(socket, ""), do: socket
  defp maybe_assign_token(socket, token), do: assign(socket, :token, token)

  defp maybe_assign_authenticated(socket, :authenticated) do
    assign(socket, :authenticated, true)
  end

  defp maybe_assign_authenticated(socket, :unauthenticated), do: socket
end
