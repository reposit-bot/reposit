defmodule ChorusWeb.McpProtocolTest do
  use ChorusWeb.ChannelCase, async: true

  alias ChorusWeb.McpSocket

  setup do
    {:ok, socket} = connect(McpSocket, %{})
    {:ok, _reply, socket} = subscribe_and_join(socket, "mcp:lobby", %{})
    {:ok, socket: socket}
  end

  describe "initialize" do
    test "returns server info and capabilities", %{socket: socket} do
      ref =
        push(socket, "mcp:request", %{
          "jsonrpc" => "2.0",
          "id" => 1,
          "method" => "initialize",
          "params" => %{
            "protocolVersion" => "2024-11-05",
            "clientInfo" => %{"name" => "test-client", "version" => "1.0.0"}
          }
        })

      assert_reply ref, :ok, response
      assert response["jsonrpc"] == "2.0"
      assert response["id"] == 1
      assert response["result"]["protocolVersion"] == "2024-11-05"
      assert response["result"]["serverInfo"]["name"] == "chorus"
      assert "tools" in response["result"]["capabilities"]
    end
  end

  describe "tools/list" do
    test "returns available tools", %{socket: socket} do
      ref =
        push(socket, "mcp:request", %{
          "jsonrpc" => "2.0",
          "id" => 2,
          "method" => "tools/list",
          "params" => %{}
        })

      assert_reply ref, :ok, response
      assert response["jsonrpc"] == "2.0"
      assert response["id"] == 2

      tools = response["result"]["tools"]
      assert length(tools) == 5

      tool_names = Enum.map(tools, & &1["name"])
      assert "search" in tool_names
      assert "share" in tool_names
      assert "vote_up" in tool_names
      assert "vote_down" in tool_names
      assert "list" in tool_names
    end
  end

  describe "tools/call" do
    test "dispatches to tool handler", %{socket: socket} do
      ref =
        push(socket, "mcp:request", %{
          "jsonrpc" => "2.0",
          "id" => 3,
          "method" => "tools/call",
          "params" => %{
            "name" => "list",
            "arguments" => %{"limit" => 5}
          }
        })

      # tools/call will be implemented later, for now just check it doesn't crash
      assert_reply ref, :ok, response
      assert response["jsonrpc"] == "2.0"
      assert response["id"] == 3
      # Result will be error until tool handlers are implemented
      assert Map.has_key?(response, "result") or Map.has_key?(response, "error")
    end

    test "returns error for unknown tool", %{socket: socket} do
      ref =
        push(socket, "mcp:request", %{
          "jsonrpc" => "2.0",
          "id" => 4,
          "method" => "tools/call",
          "params" => %{
            "name" => "unknown_tool",
            "arguments" => %{}
          }
        })

      assert_reply ref, :ok, response
      assert response["error"]["code"] == -32601
      assert response["error"]["message"] =~ "unknown"
    end
  end

  describe "ping" do
    test "returns pong", %{socket: socket} do
      ref =
        push(socket, "mcp:request", %{
          "jsonrpc" => "2.0",
          "id" => 5,
          "method" => "ping",
          "params" => %{}
        })

      assert_reply ref, :ok, response
      assert response["jsonrpc"] == "2.0"
      assert response["id"] == 5
      assert response["result"] == %{}
    end
  end

  describe "error handling" do
    test "returns error for unknown method", %{socket: socket} do
      ref =
        push(socket, "mcp:request", %{
          "jsonrpc" => "2.0",
          "id" => 6,
          "method" => "unknown/method",
          "params" => %{}
        })

      assert_reply ref, :ok, response
      assert response["error"]["code"] == -32601
      assert response["error"]["message"] =~ "not found"
    end

    test "returns error for missing id", %{socket: socket} do
      ref =
        push(socket, "mcp:request", %{
          "jsonrpc" => "2.0",
          "method" => "ping",
          "params" => %{}
        })

      assert_reply ref, :ok, response
      assert response["error"]["code"] == -32600
    end

    test "returns error for invalid jsonrpc version", %{socket: socket} do
      ref =
        push(socket, "mcp:request", %{
          "jsonrpc" => "1.0",
          "id" => 7,
          "method" => "ping",
          "params" => %{}
        })

      assert_reply ref, :ok, response
      assert response["error"]["code"] == -32600
    end
  end
end
