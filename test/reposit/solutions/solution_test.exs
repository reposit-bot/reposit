defmodule Reposit.Solutions.SolutionTest do
  use Reposit.DataCase, async: true

  import Reposit.AccountsFixtures

  alias Reposit.Solutions.Solution

  setup do
    user = user_fixture()
    {:ok, user: user}
  end

  describe "changeset/2" do
    test "valid attributes create a valid changeset", %{user: user} do
      attrs = %{
        problem: "This is a valid problem description that is at least 20 characters long.",
        solution:
          "This is a valid solution pattern that explains how to solve the problem in at least 50 characters.",
        user_id: user.id
      }

      changeset = Solution.changeset(%Solution{}, attrs)
      assert changeset.valid?
    end

    test "user_id is required" do
      attrs = %{
        problem: "This is a valid problem description that is at least 20 characters long.",
        solution:
          "This is a valid solution pattern that explains how to solve the problem in at least 50 characters."
      }

      changeset = Solution.changeset(%Solution{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).user_id
    end

    test "problem is required", %{user: user} do
      attrs = %{
        solution:
          "This is a valid solution pattern that explains how to solve the problem in at least 50 characters.",
        user_id: user.id
      }

      changeset = Solution.changeset(%Solution{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).problem
    end

    test "solution is required", %{user: user} do
      attrs = %{
        problem: "This is a valid problem description that is at least 20 characters long.",
        user_id: user.id
      }

      changeset = Solution.changeset(%Solution{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).solution
    end

    test "problem must be at least 20 characters", %{user: user} do
      attrs = %{
        problem: "too short",
        solution:
          "This is a valid solution pattern that explains how to solve the problem in at least 50 characters.",
        user_id: user.id
      }

      changeset = Solution.changeset(%Solution{}, attrs)
      refute changeset.valid?
      assert "should be at least 20 character(s)" in errors_on(changeset).problem
    end

    test "solution must be at least 50 characters", %{user: user} do
      attrs = %{
        problem: "This is a valid problem description that is at least 20 characters long.",
        solution: "too short",
        user_id: user.id
      }

      changeset = Solution.changeset(%Solution{}, attrs)
      refute changeset.valid?
      assert "should be at least 50 character(s)" in errors_on(changeset).solution
    end

    test "tags default to empty arrays", %{user: user} do
      attrs = %{
        problem: "This is a valid problem description that is at least 20 characters long.",
        solution:
          "This is a valid solution pattern that explains how to solve the problem in at least 50 characters.",
        user_id: user.id
      }

      changeset = Solution.changeset(%Solution{}, attrs)

      assert get_field(changeset, :tags) == %{
               language: [],
               framework: [],
               domain: [],
               platform: []
             }
    end

    test "tags can be set with valid keys", %{user: user} do
      attrs = %{
        problem: "This is a valid problem description that is at least 20 characters long.",
        solution:
          "This is a valid solution pattern that explains how to solve the problem in at least 50 characters.",
        user_id: user.id,
        tags: %{language: ["elixir"], framework: ["phoenix"]}
      }

      changeset = Solution.changeset(%Solution{}, attrs)
      assert changeset.valid?
    end

    test "upvotes and downvotes default to 0", %{user: user} do
      attrs = %{
        problem: "This is a valid problem description that is at least 20 characters long.",
        solution:
          "This is a valid solution pattern that explains how to solve the problem in at least 50 characters.",
        user_id: user.id
      }

      changeset = Solution.changeset(%Solution{}, attrs)
      assert get_field(changeset, :upvotes) == 0
      assert get_field(changeset, :downvotes) == 0
    end

    test "embedding can be set with a vector", %{user: user} do
      vector = List.duplicate(0.1, 1536)

      attrs = %{
        problem: "This is a valid problem description that is at least 20 characters long.",
        solution:
          "This is a valid solution pattern that explains how to solve the problem in at least 50 characters.",
        user_id: user.id,
        embedding: vector
      }

      changeset = Solution.changeset(%Solution{}, attrs)
      assert changeset.valid?
    end
  end

  describe "vote_changeset/2" do
    test "allows updating upvotes and downvotes" do
      solution = %Solution{upvotes: 5, downvotes: 2}
      changeset = Solution.vote_changeset(solution, %{upvotes: 6})
      assert changeset.valid?
      assert get_change(changeset, :upvotes) == 6
    end

    test "validates upvotes cannot be negative" do
      solution = %Solution{}
      changeset = Solution.vote_changeset(solution, %{upvotes: -1})
      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).upvotes
    end

    test "validates downvotes cannot be negative" do
      solution = %Solution{}
      changeset = Solution.vote_changeset(solution, %{downvotes: -1})
      refute changeset.valid?
      assert "must be greater than or equal to 0" in errors_on(changeset).downvotes
    end
  end

  describe "score/1" do
    test "calculates score as upvotes minus downvotes" do
      solution = %Solution{upvotes: 10, downvotes: 3}
      assert Solution.score(solution) == 7
    end

    test "score can be negative" do
      solution = %Solution{upvotes: 2, downvotes: 5}
      assert Solution.score(solution) == -3
    end
  end
end
