defmodule Chorus.Solutions.SolutionTest do
  use Chorus.DataCase, async: true

  alias Chorus.Solutions.Solution

  @valid_attrs %{
    problem_description:
      "This is a valid problem description that is at least 20 characters long.",
    solution_pattern:
      "This is a valid solution pattern that explains how to solve the problem in at least 50 characters."
  }

  describe "changeset/2" do
    test "valid attributes create a valid changeset" do
      changeset = Solution.changeset(%Solution{}, @valid_attrs)
      assert changeset.valid?
    end

    test "problem_description is required" do
      attrs = Map.delete(@valid_attrs, :problem_description)
      changeset = Solution.changeset(%Solution{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).problem_description
    end

    test "solution_pattern is required" do
      attrs = Map.delete(@valid_attrs, :solution_pattern)
      changeset = Solution.changeset(%Solution{}, attrs)
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).solution_pattern
    end

    test "problem_description must be at least 20 characters" do
      attrs = Map.put(@valid_attrs, :problem_description, "too short")
      changeset = Solution.changeset(%Solution{}, attrs)
      refute changeset.valid?
      assert "should be at least 20 character(s)" in errors_on(changeset).problem_description
    end

    test "solution_pattern must be at least 50 characters" do
      attrs = Map.put(@valid_attrs, :solution_pattern, "too short")
      changeset = Solution.changeset(%Solution{}, attrs)
      refute changeset.valid?
      assert "should be at least 50 character(s)" in errors_on(changeset).solution_pattern
    end

    test "tags default to empty arrays" do
      changeset = Solution.changeset(%Solution{}, @valid_attrs)

      assert get_field(changeset, :tags) == %{
               language: [],
               framework: [],
               domain: [],
               platform: []
             }
    end

    test "tags can be set with valid keys" do
      attrs = Map.put(@valid_attrs, :tags, %{language: ["elixir"], framework: ["phoenix"]})
      changeset = Solution.changeset(%Solution{}, attrs)
      assert changeset.valid?
    end

    test "upvotes and downvotes default to 0" do
      changeset = Solution.changeset(%Solution{}, @valid_attrs)
      assert get_field(changeset, :upvotes) == 0
      assert get_field(changeset, :downvotes) == 0
    end

    test "embedding can be set with a vector" do
      vector = List.duplicate(0.1, 1536)
      attrs = Map.put(@valid_attrs, :embedding, vector)
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
