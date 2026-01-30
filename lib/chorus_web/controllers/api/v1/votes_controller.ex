defmodule ChorusWeb.Api.V1.VotesController do
  use ChorusWeb, :controller

  alias Chorus.Votes
  alias Chorus.Solutions

  @doc """
  Upvote a solution.

  POST /api/v1/solutions/:solution_id/upvote
  """
  def upvote(conn, %{"solution_id" => solution_id} = params) do
    agent_session_id = get_agent_session_id(conn, params)

    attrs = %{
      solution_id: solution_id,
      agent_session_id: agent_session_id,
      vote_type: :up
    }

    case Votes.create_vote(attrs) do
      {:ok, _vote} ->
        {:ok, solution} = Solutions.get_solution(solution_id)

        json(conn, %{
          success: true,
          data: %{
            solution_id: solution_id,
            upvotes: solution.upvotes,
            downvotes: solution.downvotes,
            your_vote: "up"
          }
        })

      {:error, :solution_not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: "not_found",
          hint: "Solution not found"
        })

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: "validation_failed",
          hint: format_changeset_errors(changeset)
        })
    end
  end

  @doc """
  Downvote a solution.

  POST /api/v1/solutions/:solution_id/downvote
  """
  def downvote(conn, %{"solution_id" => solution_id} = params) do
    agent_session_id = get_agent_session_id(conn, params)

    attrs = %{
      solution_id: solution_id,
      agent_session_id: agent_session_id,
      vote_type: :down,
      comment: Map.get(params, "comment"),
      reason: parse_reason(Map.get(params, "reason"))
    }

    case Votes.create_vote(attrs) do
      {:ok, _vote} ->
        {:ok, solution} = Solutions.get_solution(solution_id)

        json(conn, %{
          success: true,
          data: %{
            solution_id: solution_id,
            upvotes: solution.upvotes,
            downvotes: solution.downvotes,
            your_vote: "down"
          }
        })

      {:error, :solution_not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: "not_found",
          hint: "Solution not found"
        })

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: "validation_failed",
          hint: format_changeset_errors(changeset)
        })
    end
  end

  # Get agent session ID from header or body
  defp get_agent_session_id(conn, params) do
    case get_req_header(conn, "x-agent-session-id") do
      [session_id | _] -> session_id
      [] -> Map.get(params, "agent_session_id", generate_session_id())
    end
  end

  defp generate_session_id do
    "anon-" <> Base.encode16(:crypto.strong_rand_bytes(8), case: :lower)
  end

  defp parse_reason(nil), do: nil

  defp parse_reason(reason) when is_binary(reason) do
    case reason do
      "incorrect" -> :incorrect
      "outdated" -> :outdated
      "incomplete" -> :incomplete
      "harmful" -> :harmful
      "duplicate" -> :duplicate
      "other" -> :other
      _ -> nil
    end
  end

  defp parse_reason(reason), do: reason

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
