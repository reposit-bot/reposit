defmodule ChorusWeb.McpToolsTest do
  use ExUnit.Case, async: true

  alias ChorusWeb.McpTools

  describe "list_tools/0" do
    test "returns all available tools" do
      tools = McpTools.list_tools()

      assert length(tools) == 5

      tool_names = Enum.map(tools, & &1.name)
      assert "search" in tool_names
      assert "share" in tool_names
      assert "vote_up" in tool_names
      assert "vote_down" in tool_names
      assert "list" in tool_names
    end

    test "each tool has required fields" do
      for tool <- McpTools.list_tools() do
        assert is_binary(tool.name)
        assert is_binary(tool.description)
        assert is_map(tool.inputSchema)
        assert tool.inputSchema["type"] == "object"
      end
    end
  end

  describe "get_tool/1" do
    test "returns tool by name" do
      {:ok, tool} = McpTools.get_tool("search")
      assert tool.name == "search"
    end

    test "returns error for unknown tool" do
      assert {:error, :not_found} = McpTools.get_tool("unknown")
    end
  end

  describe "search tool" do
    test "has correct schema" do
      {:ok, tool} = McpTools.get_tool("search")

      assert tool.inputSchema["required"] == ["query"]
      assert tool.inputSchema["properties"]["query"]["type"] == "string"
      assert tool.inputSchema["properties"]["tags"]["type"] == "object"
      assert tool.inputSchema["properties"]["limit"]["type"] == "integer"
    end
  end

  describe "share tool" do
    test "has correct schema" do
      {:ok, tool} = McpTools.get_tool("share")

      assert "problem" in tool.inputSchema["required"]
      assert "solution" in tool.inputSchema["required"]
      assert tool.inputSchema["properties"]["problem"]["type"] == "string"
      assert tool.inputSchema["properties"]["solution"]["type"] == "string"
      assert tool.inputSchema["properties"]["tags"]["type"] == "object"
    end
  end

  describe "vote_up tool" do
    test "has correct schema" do
      {:ok, tool} = McpTools.get_tool("vote_up")

      assert tool.inputSchema["required"] == ["solution_id"]
      assert tool.inputSchema["properties"]["solution_id"]["type"] == "string"
    end
  end

  describe "vote_down tool" do
    test "has correct schema" do
      {:ok, tool} = McpTools.get_tool("vote_down")

      assert "solution_id" in tool.inputSchema["required"]
      assert "reason" in tool.inputSchema["required"]
      assert "comment" in tool.inputSchema["required"]
      assert tool.inputSchema["properties"]["solution_id"]["type"] == "string"
      assert tool.inputSchema["properties"]["reason"]["enum"] != nil
      assert tool.inputSchema["properties"]["comment"]["type"] == "string"
    end
  end

  describe "list tool" do
    test "has correct schema" do
      {:ok, tool} = McpTools.get_tool("list")

      assert tool.inputSchema["required"] == []
      assert tool.inputSchema["properties"]["sort"]["enum"] == ["newest", "score"]
      assert tool.inputSchema["properties"]["limit"]["type"] == "integer"
    end
  end
end
