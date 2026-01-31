defmodule ChorusWeb.McpSocketTest do
  use ChorusWeb.ChannelCase, async: true

  alias ChorusWeb.McpSocket

  describe "connect/3" do
    test "connects without auth token" do
      assert {:ok, _socket} = connect(McpSocket, %{})
    end

    test "connects with auth token" do
      # Uses the valid token configured in test.exs
      assert {:ok, socket} = connect(McpSocket, %{"token" => "test-token-123"})
      assert socket.assigns.token == "test-token-123"
      assert socket.assigns.authenticated == true
    end
  end

  describe "id/1" do
    test "returns nil for anonymous connections" do
      {:ok, socket} = connect(McpSocket, %{})
      assert McpSocket.id(socket) == nil
    end
  end
end
