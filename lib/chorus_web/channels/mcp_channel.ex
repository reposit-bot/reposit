defmodule ChorusWeb.McpChannel do
  @moduledoc """
  Channel handler for MCP (Model Context Protocol) communication.

  Handles MCP protocol messages including:
  - initialize - Server handshake
  - tools/list - Tool discovery
  - tools/call - Tool invocation
  - ping - Connection health check

  Messages follow the JSON-RPC 2.0 format as specified by MCP.
  """
  use Phoenix.Channel

  alias ChorusWeb.McpTools
  alias ChorusWeb.McpToolHandlers

  # MCP Protocol version
  @protocol_version "2024-11-05"

  # JSON-RPC error codes
  @error_invalid_request -32600
  @error_method_not_found -32601
  @error_invalid_params -32602

  @impl true
  def join("mcp:lobby", _payload, socket) do
    {:ok, %{status: "connected"}, socket}
  end

  def join(_topic, _payload, _socket) do
    {:error, %{reason: "invalid_topic"}}
  end

  @impl true
  def handle_in("mcp:request", payload, socket) do
    response = handle_mcp_request(payload)
    {:reply, {:ok, response}, socket}
  end

  # Keep simple ping for backwards compatibility
  def handle_in("ping", _payload, socket) do
    {:reply, {:ok, %{message: "pong"}}, socket}
  end

  def handle_in(_event, _payload, socket) do
    {:reply, {:error, %{reason: "unknown_event"}}, socket}
  end

  # MCP Request Handling

  defp handle_mcp_request(%{"jsonrpc" => "2.0", "id" => id, "method" => method} = request)
       when is_integer(id) or is_binary(id) do
    params = Map.get(request, "params", %{})

    case dispatch_method(method, params) do
      {:ok, result} ->
        success_response(id, result)

      {:error, code, message} ->
        error_response(id, code, message)
    end
  end

  defp handle_mcp_request(%{"jsonrpc" => version}) when version != "2.0" do
    error_response(nil, @error_invalid_request, "Invalid JSON-RPC version, expected 2.0")
  end

  defp handle_mcp_request(%{"jsonrpc" => "2.0"}) do
    error_response(nil, @error_invalid_request, "Missing required field: id")
  end

  defp handle_mcp_request(_) do
    error_response(nil, @error_invalid_request, "Invalid request format")
  end

  # Method Dispatch

  defp dispatch_method("initialize", params) do
    handle_initialize(params)
  end

  defp dispatch_method("tools/list", _params) do
    handle_tools_list()
  end

  defp dispatch_method("tools/call", params) do
    handle_tools_call(params)
  end

  defp dispatch_method("ping", _params) do
    {:ok, %{}}
  end

  defp dispatch_method(method, _params) do
    {:error, @error_method_not_found, "Method not found: #{method}"}
  end

  # Method Handlers

  defp handle_initialize(_params) do
    {:ok,
     %{
       "protocolVersion" => @protocol_version,
       "serverInfo" => %{
         "name" => "chorus",
         "version" => "0.1.0"
       },
       "capabilities" => ["tools"]
     }}
  end

  defp handle_tools_list do
    {:ok, %{"tools" => McpTools.to_mcp_format()}}
  end

  defp handle_tools_call(%{"name" => name, "arguments" => arguments}) do
    case McpTools.get_tool(name) do
      {:ok, _tool} ->
        dispatch_tool(name, arguments)

      {:error, :not_found} ->
        {:error, @error_method_not_found, "Unknown tool: #{name}"}
    end
  end

  defp handle_tools_call(%{"name" => _name}) do
    {:error, @error_invalid_params, "Missing required field: arguments"}
  end

  defp handle_tools_call(_) do
    {:error, @error_invalid_params, "Missing required field: name"}
  end

  defp dispatch_tool("search", args), do: McpToolHandlers.handle_search(args)
  defp dispatch_tool("share", args), do: McpToolHandlers.handle_share(args)
  defp dispatch_tool("vote_up", args), do: McpToolHandlers.handle_vote_up(args)
  defp dispatch_tool("vote_down", args), do: McpToolHandlers.handle_vote_down(args)
  defp dispatch_tool("list", args), do: McpToolHandlers.handle_list(args)

  # Response Builders

  defp success_response(id, result) do
    %{
      "jsonrpc" => "2.0",
      "id" => id,
      "result" => result
    }
  end

  defp error_response(id, code, message) do
    %{
      "jsonrpc" => "2.0",
      "id" => id,
      "error" => %{
        "code" => code,
        "message" => message
      }
    }
  end
end
