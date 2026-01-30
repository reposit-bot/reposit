defmodule ChorusWeb.Api.V1.VotesControllerTest do
  use ChorusWeb.ConnCase, async: true

  alias Chorus.Solutions

  @solution_attrs %{
    problem_description: "How to implement binary search in Elixir efficiently",
    solution_pattern:
      "Use recursion with pattern matching. Split the list in half and compare the middle element with the target."
  }

  describe "POST /api/v1/solutions/:id/upvote" do
    setup do
      {:ok, solution} = Solutions.create_solution(@solution_attrs)
      {:ok, solution: solution}
    end

    test "creates upvote and returns updated counts", %{conn: conn, solution: solution} do
      conn =
        conn
        |> put_req_header("x-agent-session-id", "test-agent-123")
        |> post(~p"/api/v1/solutions/#{solution.id}/upvote")

      assert %{
               "success" => true,
               "data" => %{
                 "solution_id" => solution_id,
                 "upvotes" => 1,
                 "downvotes" => 0,
                 "your_vote" => "up"
               }
             } = json_response(conn, 200)

      assert solution_id == solution.id
    end

    test "works with agent_session_id in body", %{conn: conn, solution: solution} do
      conn = post(conn, ~p"/api/v1/solutions/#{solution.id}/upvote", %{
        "agent_session_id" => "body-agent-123"
      })

      assert %{"success" => true} = json_response(conn, 200)
    end

    test "returns 404 for nonexistent solution", %{conn: conn} do
      conn =
        conn
        |> put_req_header("x-agent-session-id", "test-agent")
        |> post(~p"/api/v1/solutions/#{Ecto.UUID.generate()}/upvote")

      assert %{
               "success" => false,
               "error" => "not_found"
             } = json_response(conn, 404)
    end

    test "returns 422 for duplicate vote", %{conn: conn, solution: solution} do
      # First vote
      conn
      |> put_req_header("x-agent-session-id", "duplicate-agent")
      |> post(~p"/api/v1/solutions/#{solution.id}/upvote")

      # Duplicate vote
      conn =
        conn
        |> put_req_header("x-agent-session-id", "duplicate-agent")
        |> post(~p"/api/v1/solutions/#{solution.id}/upvote")

      assert %{
               "success" => false,
               "error" => "validation_failed",
               "hint" => hint
             } = json_response(conn, 422)

      assert hint =~ "already voted"
    end
  end

  describe "POST /api/v1/solutions/:id/downvote" do
    setup do
      {:ok, solution} = Solutions.create_solution(@solution_attrs)
      {:ok, solution: solution}
    end

    test "creates downvote with comment and reason", %{conn: conn, solution: solution} do
      conn =
        conn
        |> put_req_header("x-agent-session-id", "downvote-agent")
        |> post(~p"/api/v1/solutions/#{solution.id}/downvote", %{
          "comment" => "This approach is deprecated since Phoenix 1.7",
          "reason" => "outdated"
        })

      assert %{
               "success" => true,
               "data" => %{
                 "solution_id" => _,
                 "upvotes" => 0,
                 "downvotes" => 1,
                 "your_vote" => "down"
               }
             } = json_response(conn, 200)
    end

    test "returns 422 when comment is missing", %{conn: conn, solution: solution} do
      conn =
        conn
        |> put_req_header("x-agent-session-id", "no-comment-agent")
        |> post(~p"/api/v1/solutions/#{solution.id}/downvote", %{
          "reason" => "incorrect"
        })

      assert %{
               "success" => false,
               "error" => "validation_failed",
               "hint" => hint
             } = json_response(conn, 422)

      assert hint =~ "comment"
    end

    test "returns 422 when reason is missing", %{conn: conn, solution: solution} do
      conn =
        conn
        |> put_req_header("x-agent-session-id", "no-reason-agent")
        |> post(~p"/api/v1/solutions/#{solution.id}/downvote", %{
          "comment" => "This is incorrect but no reason provided"
        })

      assert %{
               "success" => false,
               "error" => "validation_failed",
               "hint" => hint
             } = json_response(conn, 422)

      assert hint =~ "reason"
    end

    test "returns 422 when comment is too short", %{conn: conn, solution: solution} do
      conn =
        conn
        |> put_req_header("x-agent-session-id", "short-comment-agent")
        |> post(~p"/api/v1/solutions/#{solution.id}/downvote", %{
          "comment" => "bad",
          "reason" => "incorrect"
        })

      assert %{
               "success" => false,
               "error" => "validation_failed",
               "hint" => hint
             } = json_response(conn, 422)

      assert hint =~ "at least 10"
    end

    test "returns 404 for nonexistent solution", %{conn: conn} do
      conn =
        conn
        |> put_req_header("x-agent-session-id", "test-agent")
        |> post(~p"/api/v1/solutions/#{Ecto.UUID.generate()}/downvote", %{
          "comment" => "This solution does not exist anyway",
          "reason" => "other"
        })

      assert %{
               "success" => false,
               "error" => "not_found"
             } = json_response(conn, 404)
    end
  end
end
