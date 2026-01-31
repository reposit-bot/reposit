defmodule ChorusWeb.McpAuthTest do
  use ChorusWeb.ChannelCase, async: true

  alias ChorusWeb.McpSocket

  describe "authentication" do
    test "connects without token for public access" do
      {:ok, socket} = connect(McpSocket, %{})
      refute Map.has_key?(socket.assigns, :authenticated)
    end

    test "connects with valid token and marks as authenticated" do
      # Use the test token configured in test environment
      {:ok, socket} = connect(McpSocket, %{"token" => "test-token-123"})
      assert socket.assigns.token == "test-token-123"
      assert socket.assigns.authenticated == true
    end

    test "rejects connection with invalid token" do
      result = connect(McpSocket, %{"token" => "invalid-token"})
      assert result == :error
    end

    test "allows empty token string as unauthenticated" do
      {:ok, socket} = connect(McpSocket, %{"token" => ""})
      refute Map.get(socket.assigns, :authenticated)
    end
  end

  describe "authenticated channel operations" do
    test "authenticated socket can join channel" do
      {:ok, socket} = connect(McpSocket, %{"token" => "test-token-123"})
      assert {:ok, _reply, _socket} = subscribe_and_join(socket, "mcp:lobby", %{})
    end

    test "unauthenticated socket can still join for public instances" do
      {:ok, socket} = connect(McpSocket, %{})
      assert {:ok, _reply, _socket} = subscribe_and_join(socket, "mcp:lobby", %{})
    end
  end
end
