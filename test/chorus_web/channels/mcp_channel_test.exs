defmodule ChorusWeb.McpChannelTest do
  use ChorusWeb.ChannelCase, async: true

  alias ChorusWeb.McpSocket

  setup do
    {:ok, socket} = connect(McpSocket, %{})
    {:ok, socket: socket}
  end

  describe "join/3" do
    test "joins mcp:lobby successfully", %{socket: socket} do
      assert {:ok, _reply, _socket} = subscribe_and_join(socket, "mcp:lobby", %{})
    end

    test "joins mcp:lobby with payload", %{socket: socket} do
      assert {:ok, _reply, _socket} =
               subscribe_and_join(socket, "mcp:lobby", %{"client_info" => %{"name" => "test"}})
    end

    test "rejects non-mcp topics at socket level", %{socket: socket} do
      # Invalid topics are rejected at the socket level, not the channel level
      assert_raise RuntimeError, ~r/no channel found for topic/, fn ->
        subscribe_and_join(socket, "invalid:topic", %{})
      end
    end
  end

  describe "handle_in/3" do
    setup %{socket: socket} do
      {:ok, _reply, socket} = subscribe_and_join(socket, "mcp:lobby", %{})
      {:ok, socket: socket}
    end

    test "handles ping message", %{socket: socket} do
      ref = push(socket, "ping", %{})
      assert_reply ref, :ok, %{message: "pong"}
    end

    test "handles unknown messages gracefully", %{socket: socket} do
      ref = push(socket, "unknown_event", %{"data" => "test"})
      assert_reply ref, :error, %{reason: "unknown_event"}
    end
  end
end
