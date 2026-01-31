defmodule Reposit.Votes.VoteTest do
  use Reposit.DataCase, async: true

  import Reposit.AccountsFixtures

  alias Reposit.Votes.Vote
  alias Reposit.Solutions.Solution

  setup do
    user = user_fixture()
    other_user = user_fixture()

    # Create a solution for testing votes
    {:ok, solution} =
      %Solution{}
      |> Solution.changeset(%{
        problem_description: "This is a valid problem description for testing purposes.",
        solution_pattern:
          "This is a valid solution pattern that explains how to solve the problem in detail.",
        user_id: user.id
      })
      |> Repo.insert()

    %{solution: solution, user: user, other_user: other_user}
  end

  describe "changeset/2 for upvotes" do
    test "valid upvote creates a valid changeset", %{solution: solution, other_user: user} do
      attrs = %{
        solution_id: solution.id,
        user_id: user.id,
        vote_type: :up
      }

      changeset = Vote.changeset(%Vote{}, attrs)
      assert changeset.valid?
    end

    test "upvote cannot have a comment", %{solution: solution, other_user: user} do
      attrs = %{
        solution_id: solution.id,
        user_id: user.id,
        vote_type: :up,
        comment: "This is a comment"
      }

      changeset = Vote.changeset(%Vote{}, attrs)
      refute changeset.valid?
      assert "cannot be set for upvotes" in errors_on(changeset).comment
    end

    test "upvote cannot have a reason", %{solution: solution, other_user: user} do
      attrs = %{
        solution_id: solution.id,
        user_id: user.id,
        vote_type: :up,
        reason: :incorrect
      }

      changeset = Vote.changeset(%Vote{}, attrs)
      refute changeset.valid?
      assert "cannot be set for upvotes" in errors_on(changeset).reason
    end
  end

  describe "changeset/2 for downvotes" do
    test "valid downvote requires comment and reason", %{solution: solution, other_user: user} do
      attrs = %{
        solution_id: solution.id,
        user_id: user.id,
        vote_type: :down,
        comment: "This solution is incorrect because it doesn't handle edge cases.",
        reason: :incorrect
      }

      changeset = Vote.changeset(%Vote{}, attrs)
      assert changeset.valid?
    end

    test "downvote requires a comment", %{solution: solution, other_user: user} do
      attrs = %{
        solution_id: solution.id,
        user_id: user.id,
        vote_type: :down,
        reason: :incorrect
      }

      changeset = Vote.changeset(%Vote{}, attrs)
      refute changeset.valid?
      assert "is required for downvotes" in errors_on(changeset).comment
    end

    test "downvote requires a reason", %{solution: solution, other_user: user} do
      attrs = %{
        solution_id: solution.id,
        user_id: user.id,
        vote_type: :down,
        comment: "This solution is incorrect."
      }

      changeset = Vote.changeset(%Vote{}, attrs)
      refute changeset.valid?
      assert "is required for downvotes" in errors_on(changeset).reason
    end

    test "downvote comment must be at least 10 characters", %{
      solution: solution,
      other_user: user
    } do
      attrs = %{
        solution_id: solution.id,
        user_id: user.id,
        vote_type: :down,
        comment: "too short",
        reason: :incorrect
      }

      changeset = Vote.changeset(%Vote{}, attrs)
      refute changeset.valid?
      assert "must be at least 10 characters" in errors_on(changeset).comment
    end

    test "all downvote reasons are valid", %{solution: solution, other_user: user} do
      for reason <- Vote.downvote_reasons() do
        attrs = %{
          solution_id: solution.id,
          user_id: user.id,
          vote_type: :down,
          comment: "This is a valid comment for #{reason}.",
          reason: reason
        }

        changeset = Vote.changeset(%Vote{}, attrs)
        assert changeset.valid?, "Expected valid changeset for reason: #{reason}"
      end
    end
  end

  describe "changeset/2 required fields" do
    test "solution_id is required", %{other_user: user} do
      attrs = %{user_id: user.id, vote_type: :up}
      changeset = Vote.changeset(%Vote{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).solution_id
    end

    test "user_id is required", %{solution: solution} do
      attrs = %{solution_id: solution.id, vote_type: :up}
      changeset = Vote.changeset(%Vote{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).user_id
    end

    test "vote_type is required", %{solution: solution, other_user: user} do
      attrs = %{solution_id: solution.id, user_id: user.id}
      changeset = Vote.changeset(%Vote{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).vote_type
    end
  end

  describe "unique constraint" do
    test "same user cannot vote twice on the same solution", %{
      solution: solution,
      other_user: user
    } do
      attrs = %{
        solution_id: solution.id,
        user_id: user.id,
        vote_type: :up
      }

      # First vote should succeed
      {:ok, _vote} =
        %Vote{}
        |> Vote.changeset(attrs)
        |> Repo.insert()

      # Second vote should fail
      {:error, changeset} =
        %Vote{}
        |> Vote.changeset(attrs)
        |> Repo.insert()

      assert "already voted on this solution" in errors_on(changeset).solution_id
    end
  end
end
