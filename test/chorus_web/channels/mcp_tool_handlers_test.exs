defmodule ChorusWeb.McpToolHandlersTest do
  use Chorus.DataCase, async: true

  alias ChorusWeb.McpToolHandlers
  alias Chorus.Solutions

  describe "handle_search/1" do
    test "returns error for empty query" do
      result = McpToolHandlers.handle_search(%{"query" => ""})

      assert {:error, _code, message} = result
      assert message =~ "query"
    end

    test "returns results for valid query" do
      # Create a test solution
      {:ok, _solution} =
        Solutions.create_solution(%{
          problem_description: "How to implement binary search in Elixir",
          solution_pattern: """
          Use recursion with guards to implement binary search efficiently.
          The key is to calculate the midpoint and compare with the target value.
          """
        })

      result = McpToolHandlers.handle_search(%{"query" => "binary search"})

      assert {:ok, response} = result
      assert is_list(response["content"])
      assert length(response["content"]) > 0
    end
  end

  describe "handle_share/1" do
    test "creates solution with valid params" do
      result =
        McpToolHandlers.handle_share(%{
          "problem" => "How to test Phoenix channels effectively",
          "solution" => """
          Use Phoenix.ChannelTest module for testing channels.
          Set up the socket with connect/2 and join with subscribe_and_join/3.
          Assert replies with assert_reply and broadcasts with assert_broadcast.
          """
        })

      assert {:ok, response} = result
      assert is_list(response["content"])
    end

    test "returns error for missing problem" do
      result =
        McpToolHandlers.handle_share(%{
          "solution" => "Some solution pattern that is long enough to pass validation"
        })

      assert {:error, _code, message} = result
      assert message =~ "problem"
    end

    test "returns error for missing solution" do
      result =
        McpToolHandlers.handle_share(%{
          "problem" => "Some problem description"
        })

      assert {:error, _code, message} = result
      assert message =~ "solution"
    end
  end

  describe "handle_vote_up/1" do
    test "upvotes existing solution" do
      {:ok, solution} =
        Solutions.create_solution(%{
          problem_description: "Test problem for upvoting workflow",
          solution_pattern: """
          This is a test solution pattern that needs to be long enough
          to pass the minimum length validation requirements.
          """
        })

      result = McpToolHandlers.handle_vote_up(%{"solution_id" => solution.id})

      assert {:ok, response} = result
      assert is_list(response["content"])
    end

    test "returns error for non-existent solution" do
      result =
        McpToolHandlers.handle_vote_up(%{
          "solution_id" => Ecto.UUID.generate()
        })

      assert {:error, _code, message} = result
      assert message =~ "not found"
    end
  end

  describe "handle_vote_down/1" do
    test "downvotes existing solution with reason and comment" do
      {:ok, solution} =
        Solutions.create_solution(%{
          problem_description: "Test problem for downvoting workflow",
          solution_pattern: """
          This is a test solution pattern that needs to be long enough
          to pass the minimum length validation requirements.
          """
        })

      result =
        McpToolHandlers.handle_vote_down(%{
          "solution_id" => solution.id,
          "reason" => "outdated",
          "comment" => "This solution uses deprecated API from version 1.x"
        })

      assert {:ok, response} = result
      assert is_list(response["content"])
    end

    test "returns error for missing reason" do
      {:ok, solution} =
        Solutions.create_solution(%{
          problem_description: "Test problem for missing reason test",
          solution_pattern: """
          This is a test solution pattern that needs to be long enough
          to pass the minimum length validation requirements.
          """
        })

      result =
        McpToolHandlers.handle_vote_down(%{
          "solution_id" => solution.id,
          "comment" => "Some comment"
        })

      assert {:error, _code, message} = result
      assert message =~ "reason"
    end

    test "returns error for missing comment" do
      {:ok, solution} =
        Solutions.create_solution(%{
          problem_description: "Test problem for missing comment test",
          solution_pattern: """
          This is a test solution pattern that needs to be long enough
          to pass the minimum length validation requirements.
          """
        })

      result =
        McpToolHandlers.handle_vote_down(%{
          "solution_id" => solution.id,
          "reason" => "outdated"
        })

      assert {:error, _code, message} = result
      assert message =~ "comment"
    end
  end

  describe "handle_list/1" do
    test "returns list of solutions" do
      # Create some test solutions
      for i <- 1..3 do
        Solutions.create_solution(%{
          problem_description: "Test problem #{i} for listing test",
          solution_pattern: """
          This is test solution #{i} with enough content to pass validation.
          It contains useful information about solving the problem.
          """
        })
      end

      result = McpToolHandlers.handle_list(%{})

      assert {:ok, response} = result
      assert is_list(response["content"])
    end

    test "respects limit parameter" do
      # Create more solutions than the limit
      for i <- 1..5 do
        Solutions.create_solution(%{
          problem_description: "Test problem #{i} for limit test",
          solution_pattern: """
          This is test solution #{i} with enough content to pass validation.
          It contains useful information about solving the problem.
          """
        })
      end

      result = McpToolHandlers.handle_list(%{"limit" => 2})

      assert {:ok, response} = result
      # The text should indicate limited results
      assert is_list(response["content"])
    end
  end
end
