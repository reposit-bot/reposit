defmodule Chorus.VotesTest do
  use Chorus.DataCase, async: true

  alias Chorus.Votes
  alias Chorus.Solutions

  @solution_attrs %{
    problem_description: "How to implement binary search in Elixir efficiently",
    solution_pattern:
      "Use recursion with pattern matching. Split the list in half and compare the middle element with the target."
  }

  describe "create_vote/1" do
    setup do
      {:ok, solution} = Solutions.create_solution(@solution_attrs)
      {:ok, solution: solution}
    end

    test "creates upvote successfully", %{solution: solution} do
      attrs = %{
        solution_id: solution.id,
        agent_session_id: "agent-123",
        vote_type: :up
      }

      assert {:ok, vote} = Votes.create_vote(attrs)
      assert vote.vote_type == :up
      assert vote.solution_id == solution.id
      assert vote.agent_session_id == "agent-123"
    end

    test "creates downvote with comment and reason", %{solution: solution} do
      attrs = %{
        solution_id: solution.id,
        agent_session_id: "agent-456",
        vote_type: :down,
        comment: "This approach is deprecated since Phoenix 1.7",
        reason: :outdated
      }

      assert {:ok, vote} = Votes.create_vote(attrs)
      assert vote.vote_type == :down
      assert vote.comment == "This approach is deprecated since Phoenix 1.7"
      assert vote.reason == :outdated
    end

    test "updates solution upvote count atomically", %{solution: solution} do
      attrs = %{
        solution_id: solution.id,
        agent_session_id: "agent-789",
        vote_type: :up
      }

      assert {:ok, _vote} = Votes.create_vote(attrs)

      # Reload solution
      {:ok, updated_solution} = Solutions.get_solution(solution.id)
      assert updated_solution.upvotes == 1
      assert updated_solution.downvotes == 0
    end

    test "updates solution downvote count atomically", %{solution: solution} do
      attrs = %{
        solution_id: solution.id,
        agent_session_id: "agent-789",
        vote_type: :down,
        comment: "This is incorrect because it doesn't handle edge cases",
        reason: :incorrect
      }

      assert {:ok, _vote} = Votes.create_vote(attrs)

      {:ok, updated_solution} = Solutions.get_solution(solution.id)
      assert updated_solution.upvotes == 0
      assert updated_solution.downvotes == 1
    end

    test "fails when solution not found" do
      attrs = %{
        solution_id: Ecto.UUID.generate(),
        agent_session_id: "agent-123",
        vote_type: :up
      }

      assert {:error, :solution_not_found} = Votes.create_vote(attrs)
    end

    test "fails for duplicate vote from same agent", %{solution: solution} do
      attrs = %{
        solution_id: solution.id,
        agent_session_id: "agent-duplicate",
        vote_type: :up
      }

      assert {:ok, _} = Votes.create_vote(attrs)
      assert {:error, %Ecto.Changeset{} = changeset} = Votes.create_vote(attrs)
      assert "already voted on this solution" in errors_on(changeset).solution_id
    end

    test "fails for downvote without comment", %{solution: solution} do
      attrs = %{
        solution_id: solution.id,
        agent_session_id: "agent-no-comment",
        vote_type: :down,
        reason: :incorrect
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Votes.create_vote(attrs)
      assert "is required for downvotes" in errors_on(changeset).comment
    end

    test "fails for downvote without reason", %{solution: solution} do
      attrs = %{
        solution_id: solution.id,
        agent_session_id: "agent-no-reason",
        vote_type: :down,
        comment: "This is incorrect but I have no reason"
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Votes.create_vote(attrs)
      assert "is required for downvotes" in errors_on(changeset).reason
    end

    test "fails for downvote with short comment", %{solution: solution} do
      attrs = %{
        solution_id: solution.id,
        agent_session_id: "agent-short-comment",
        vote_type: :down,
        comment: "bad",
        reason: :incorrect
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Votes.create_vote(attrs)
      assert "must be at least 10 characters" in errors_on(changeset).comment
    end
  end

  describe "get_vote/2" do
    setup do
      {:ok, solution} = Solutions.create_solution(@solution_attrs)
      {:ok, solution: solution}
    end

    test "returns vote when found", %{solution: solution} do
      attrs = %{
        solution_id: solution.id,
        agent_session_id: "agent-get-test",
        vote_type: :up
      }

      {:ok, _} = Votes.create_vote(attrs)

      vote = Votes.get_vote(solution.id, "agent-get-test")
      assert vote.vote_type == :up
    end

    test "returns nil when not found", %{solution: solution} do
      assert nil == Votes.get_vote(solution.id, "nonexistent")
    end
  end
end
