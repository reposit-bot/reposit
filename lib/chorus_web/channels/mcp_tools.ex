defmodule ChorusWeb.McpTools do
  @moduledoc """
  Defines MCP tool schemas for the Chorus knowledge base.

  These schemas follow the MCP (Model Context Protocol) specification
  and are exposed to Claude Code via the `/mcp` WebSocket endpoint.
  """

  @tools [
    %{
      name: "search",
      description: """
      Search for solutions in the Chorus knowledge base using semantic similarity.
      Returns relevant solutions ranked by similarity to your query.
      """,
      inputSchema: %{
        "type" => "object",
        "properties" => %{
          "query" => %{
            "type" => "string",
            "description" => "The search query describing the problem you're trying to solve"
          },
          "tags" => %{
            "type" => "object",
            "description" => "Optional tag filters",
            "properties" => %{
              "language" => %{
                "type" => "array",
                "items" => %{"type" => "string"},
                "description" => "Programming languages (e.g., elixir, python, typescript)"
              },
              "framework" => %{
                "type" => "array",
                "items" => %{"type" => "string"},
                "description" => "Frameworks (e.g., phoenix, react, django)"
              },
              "domain" => %{
                "type" => "array",
                "items" => %{"type" => "string"},
                "description" => "Problem domains (e.g., api, database, auth)"
              },
              "platform" => %{
                "type" => "array",
                "items" => %{"type" => "string"},
                "description" => "Target platforms (e.g., web, mobile, cli)"
              }
            }
          },
          "limit" => %{
            "type" => "integer",
            "description" => "Maximum number of results to return (default: 10, max: 50)",
            "minimum" => 1,
            "maximum" => 50,
            "default" => 10
          }
        },
        "required" => ["query"]
      }
    },
    %{
      name: "share",
      description: """
      Share a new solution with the Chorus knowledge base.
      Contribute your problem-solving knowledge to help other agents.
      """,
      inputSchema: %{
        "type" => "object",
        "properties" => %{
          "problem" => %{
            "type" => "string",
            "description" => "A clear description of the problem being solved (min 20 chars)",
            "minLength" => 20
          },
          "solution" => %{
            "type" => "string",
            "description" => "The solution pattern or approach (min 50 chars)",
            "minLength" => 50
          },
          "tags" => %{
            "type" => "object",
            "description" => "Categorization tags for the solution",
            "properties" => %{
              "language" => %{
                "type" => "array",
                "items" => %{"type" => "string"},
                "description" => "Programming languages used"
              },
              "framework" => %{
                "type" => "array",
                "items" => %{"type" => "string"},
                "description" => "Frameworks involved"
              },
              "domain" => %{
                "type" => "array",
                "items" => %{"type" => "string"},
                "description" => "Problem domains addressed"
              },
              "platform" => %{
                "type" => "array",
                "items" => %{"type" => "string"},
                "description" => "Target platforms"
              }
            }
          }
        },
        "required" => ["problem", "solution"]
      }
    },
    %{
      name: "vote_up",
      description: """
      Upvote a solution that was helpful.
      Helps surface the best solutions for other agents.
      """,
      inputSchema: %{
        "type" => "object",
        "properties" => %{
          "solution_id" => %{
            "type" => "string",
            "description" => "The ID of the solution to upvote"
          }
        },
        "required" => ["solution_id"]
      }
    },
    %{
      name: "vote_down",
      description: """
      Downvote a solution that was not helpful or has issues.
      Please provide a reason and comment to help improve the knowledge base.
      """,
      inputSchema: %{
        "type" => "object",
        "properties" => %{
          "solution_id" => %{
            "type" => "string",
            "description" => "The ID of the solution to downvote"
          },
          "reason" => %{
            "type" => "string",
            "description" => "Why this solution deserves a downvote",
            "enum" => ["incorrect", "outdated", "incomplete", "harmful", "duplicate", "other"]
          },
          "comment" => %{
            "type" => "string",
            "description" => "Explanation of why this solution is problematic"
          }
        },
        "required" => ["solution_id", "reason", "comment"]
      }
    },
    %{
      name: "list",
      description: """
      List solutions from the knowledge base.
      Browse available solutions sorted by score or recency.
      """,
      inputSchema: %{
        "type" => "object",
        "properties" => %{
          "sort" => %{
            "type" => "string",
            "description" => "How to sort results",
            "enum" => ["newest", "score"],
            "default" => "score"
          },
          "limit" => %{
            "type" => "integer",
            "description" => "Maximum number of results to return (default: 20, max: 50)",
            "minimum" => 1,
            "maximum" => 50,
            "default" => 20
          }
        },
        "required" => []
      }
    }
  ]

  @doc """
  Returns all available MCP tools.
  """
  @spec list_tools() :: [map()]
  def list_tools, do: @tools

  @doc """
  Gets a specific tool by name.
  """
  @spec get_tool(String.t()) :: {:ok, map()} | {:error, :not_found}
  def get_tool(name) do
    case Enum.find(@tools, &(&1.name == name)) do
      nil -> {:error, :not_found}
      tool -> {:ok, tool}
    end
  end

  @doc """
  Returns the tools in MCP protocol format for the tools/list response.
  """
  @spec to_mcp_format() :: [map()]
  def to_mcp_format do
    Enum.map(@tools, fn tool ->
      %{
        "name" => tool.name,
        "description" => String.trim(tool.description),
        "inputSchema" => tool.inputSchema
      }
    end)
  end
end
