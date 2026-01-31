defmodule ChorusWeb.McpToolHandlers do
  @moduledoc """
  Implements the actual tool execution logic for MCP tools.

  Each handler takes arguments from the tools/call request and returns
  either {:ok, response} or {:error, code, message}.
  """

  alias Chorus.Solutions
  alias Chorus.Votes

  # JSON-RPC error codes
  @error_invalid_params -32602

  @doc """
  Handles the `search` tool - semantic search for solutions.
  """
  def handle_search(%{"query" => query} = args) when is_binary(query) and byte_size(query) > 0 do
    limit = Map.get(args, "limit", 10)
    tags = Map.get(args, "tags", %{})

    case Solutions.search_solutions(query, limit: limit, required_tags: tags) do
      {:ok, results, total} ->
        text = format_search_results(results, total)
        {:ok, mcp_text_response(text)}

      {:error, reason} ->
        {:error, @error_invalid_params, "Search failed: #{inspect(reason)}"}
    end
  end

  def handle_search(_args) do
    {:error, @error_invalid_params, "Missing or empty required field: query"}
  end

  @doc """
  Handles the `share` tool - contribute a new solution.
  """
  def handle_share(%{"problem" => problem, "solution" => solution} = args)
      when is_binary(problem) and is_binary(solution) do
    tags = Map.get(args, "tags", %{})

    attrs = %{
      problem_description: problem,
      solution_pattern: solution,
      tags: normalize_tags(tags)
    }

    case Solutions.create_solution(attrs) do
      {:ok, created} ->
        text = """
        Solution shared successfully!

        ID: #{created.id}
        Problem: #{truncate(created.problem_description, 100)}

        Thank you for contributing to the Chorus knowledge base.
        """

        {:ok, mcp_text_response(text)}

      {:error, %Ecto.Changeset{} = changeset} ->
        errors = format_changeset_errors(changeset)
        {:error, @error_invalid_params, "Validation failed: #{errors}"}
    end
  end

  def handle_share(args) do
    missing =
      []
      |> then(fn acc -> if Map.has_key?(args, "problem"), do: acc, else: ["problem" | acc] end)
      |> then(fn acc -> if Map.has_key?(args, "solution"), do: acc, else: ["solution" | acc] end)
      |> Enum.reverse()
      |> Enum.join(", ")

    {:error, @error_invalid_params, "Missing required fields: #{missing}"}
  end

  @doc """
  Handles the `vote_up` tool - upvote a solution.
  """
  def handle_vote_up(%{"solution_id" => solution_id}) when is_binary(solution_id) do
    attrs = %{
      solution_id: solution_id,
      agent_session_id: generate_session_id(),
      vote_type: :up
    }

    case Votes.create_vote(attrs) do
      {:ok, _vote} ->
        {:ok, solution} = Solutions.get_solution(solution_id)

        text = """
        Upvoted successfully!

        Solution ID: #{solution_id}
        Current score: #{solution.upvotes - solution.downvotes} (#{solution.upvotes} up, #{solution.downvotes} down)
        """

        {:ok, mcp_text_response(text)}

      {:error, :solution_not_found} ->
        {:error, @error_invalid_params, "Solution not found: #{solution_id}"}

      {:error, %Ecto.Changeset{} = changeset} ->
        errors = format_changeset_errors(changeset)
        {:error, @error_invalid_params, "Vote failed: #{errors}"}
    end
  end

  def handle_vote_up(_args) do
    {:error, @error_invalid_params, "Missing required field: solution_id"}
  end

  @doc """
  Handles the `vote_down` tool - downvote a solution with reason and comment.
  """
  def handle_vote_down(
        %{"solution_id" => solution_id, "reason" => reason, "comment" => comment} = _args
      )
      when is_binary(solution_id) and is_binary(reason) and is_binary(comment) do
    attrs = %{
      solution_id: solution_id,
      agent_session_id: generate_session_id(),
      vote_type: :down,
      reason: parse_reason(reason),
      comment: comment
    }

    case Votes.create_vote(attrs) do
      {:ok, _vote} ->
        {:ok, solution} = Solutions.get_solution(solution_id)

        text = """
        Downvoted successfully!

        Solution ID: #{solution_id}
        Reason: #{reason}
        Current score: #{solution.upvotes - solution.downvotes} (#{solution.upvotes} up, #{solution.downvotes} down)

        Thank you for helping improve the knowledge base quality.
        """

        {:ok, mcp_text_response(text)}

      {:error, :solution_not_found} ->
        {:error, @error_invalid_params, "Solution not found: #{solution_id}"}

      {:error, %Ecto.Changeset{} = changeset} ->
        errors = format_changeset_errors(changeset)
        {:error, @error_invalid_params, "Vote failed: #{errors}"}
    end
  end

  def handle_vote_down(%{"solution_id" => _, "reason" => _}) do
    {:error, @error_invalid_params, "Missing required field: comment"}
  end

  def handle_vote_down(%{"solution_id" => _}) do
    {:error, @error_invalid_params, "Missing required field: reason"}
  end

  def handle_vote_down(_args) do
    {:error, @error_invalid_params, "Missing required field: solution_id"}
  end

  @doc """
  Handles the `list` tool - browse solutions.
  """
  def handle_list(args) do
    limit = Map.get(args, "limit", 20) |> min(50)
    sort = parse_sort(Map.get(args, "sort", "score"))

    solutions = Solutions.list_solutions(limit: limit, order_by: sort)

    text =
      if Enum.empty?(solutions) do
        "No solutions found in the knowledge base yet."
      else
        format_list_results(solutions)
      end

    {:ok, mcp_text_response(text)}
  end

  # Helpers

  defp mcp_text_response(text) do
    %{
      "content" => [
        %{"type" => "text", "text" => text}
      ],
      "isError" => false
    }
  end

  defp format_search_results(results, total) do
    if Enum.empty?(results) do
      "No solutions found matching your query."
    else
      header = "Found #{total} solution(s). Showing top #{length(results)}:\n\n"

      results_text =
        results
        |> Enum.with_index(1)
        |> Enum.map(fn {result, idx} ->
          """
          #{idx}. [#{result.id}] (similarity: #{Float.round(result.similarity * 100, 1)}%)
             Problem: #{truncate(result.problem_description, 100)}
             Score: #{result.upvotes - result.downvotes} (#{result.upvotes}↑ #{result.downvotes}↓)
          """
        end)
        |> Enum.join("\n")

      header <> results_text
    end
  end

  defp format_list_results(solutions) do
    header = "Showing #{length(solutions)} solution(s):\n\n"

    results_text =
      solutions
      |> Enum.with_index(1)
      |> Enum.map(fn {solution, idx} ->
        score = solution.upvotes - solution.downvotes

        """
        #{idx}. [#{solution.id}]
           Problem: #{truncate(solution.problem_description, 100)}
           Score: #{score} (#{solution.upvotes}↑ #{solution.downvotes}↓)
        """
      end)
      |> Enum.join("\n")

    header <> results_text
  end

  defp truncate(text, max_length) when is_binary(text) do
    if String.length(text) > max_length do
      String.slice(text, 0, max_length) <> "..."
    else
      text
    end
  end

  defp truncate(nil, _max_length), do: ""

  defp normalize_tags(tags) when is_map(tags) do
    # Ensure tags have the expected structure
    %{
      language: Map.get(tags, "language", []),
      framework: Map.get(tags, "framework", []),
      domain: Map.get(tags, "domain", []),
      platform: Map.get(tags, "platform", [])
    }
  end

  defp normalize_tags(_), do: %{}

  defp parse_reason(reason) when is_binary(reason) do
    case reason do
      "incorrect" -> :incorrect
      "outdated" -> :outdated
      "incomplete" -> :incomplete
      "harmful" -> :harmful
      "duplicate" -> :duplicate
      "other" -> :other
      _ -> :other
    end
  end

  defp parse_sort("newest"), do: :inserted_at
  defp parse_sort("score"), do: :score
  defp parse_sort(_), do: :score

  defp generate_session_id do
    "mcp-" <> Base.encode16(:crypto.strong_rand_bytes(8), case: :lower)
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map(fn {field, errors} ->
      "#{field}: #{Enum.join(errors, ", ")}"
    end)
    |> Enum.join("; ")
  end
end
