defmodule ChorusWeb.SolutionsLive.ShowTest do
  use ChorusWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Chorus.Solutions
  alias Chorus.Votes

  describe "Show" do
    test "renders solution details", %{conn: conn} do
      {:ok, solution} =
        create_solution(
          "How to implement binary search in Elixir",
          "Use recursion with pattern matching for an elegant solution. Here's the approach:\n\n1. Check middle element\n2. Recurse left or right"
        )

      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      # Problem description is shown in the page content
      assert render(view) =~ "How to implement binary search in Elixir"
      assert render(view) =~ "Use recursion with pattern matching"
    end

    test "renders markdown content", %{conn: conn} do
      {:ok, solution} =
        create_solution(
          "Test problem for markdown rendering",
          "Here is some **bold** text and *italic* text. This needs to be at least fifty characters long."
        )

      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      html = render(view)
      assert html =~ "<strong>bold</strong>"
      assert html =~ "<em>italic</em>"
    end

    test "displays tags grouped by category", %{conn: conn} do
      {:ok, solution} =
        create_solution(
          "Test problem with multiple tags",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{
            language: ["elixir", "erlang"],
            framework: ["phoenix"],
            domain: ["api", "web"]
          }
        )

      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      html = render(view)
      # Check tags are present
      assert html =~ "elixir"
      assert html =~ "erlang"
      assert html =~ "phoenix"
      assert html =~ "api"
      assert html =~ "web"
    end

    test "displays vote stats", %{conn: conn} do
      {:ok, solution} =
        create_solution(
          "Test problem for vote display",
          "This is a detailed solution pattern that helps solve the problem effectively"
        )

      # Update vote counts
      solution
      |> Ecto.Changeset.change(upvotes: 25, downvotes: 5)
      |> Chorus.Repo.update!()

      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      html = render(view)
      # Check vote display - shows upvotes, downvotes, and score
      assert html =~ "25"
      assert html =~ "5"
      assert html =~ "+20"
    end

    test "displays upvote percentage in radial progress", %{conn: conn} do
      {:ok, solution} =
        create_solution(
          "Test problem for percentage",
          "This is a detailed solution pattern that helps solve the problem effectively"
        )

      # 75% upvote rate (15 up, 5 down)
      solution
      |> Ecto.Changeset.change(upvotes: 15, downvotes: 5)
      |> Chorus.Repo.update!()

      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      html = render(view)
      assert html =~ "75%"
    end

    test "displays vote comments from downvotes", %{conn: conn} do
      {:ok, solution} =
        create_solution(
          "Test problem for vote comments",
          "This is a detailed solution pattern that helps solve the problem effectively"
        )

      # Create a downvote with comment
      {:ok, _vote} =
        Votes.create_vote(%{
          solution_id: solution.id,
          agent_session_id: "test-session-1",
          vote_type: :down,
          comment: "This approach is deprecated since Phoenix 1.7",
          reason: :outdated
        })

      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      html = render(view)
      assert html =~ "This approach is deprecated since Phoenix 1.7"
      assert html =~ "Outdated"
    end

    test "does not display upvote comments (they don't have any)", %{conn: conn} do
      {:ok, solution} =
        create_solution(
          "Test problem for upvote display",
          "This is a detailed solution pattern that helps solve the problem effectively"
        )

      # Create an upvote (no comment)
      {:ok, _vote} =
        Votes.create_vote(%{
          solution_id: solution.id,
          agent_session_id: "test-session-2",
          vote_type: :up
        })

      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      # Should not have the feedback section with no comments
      refute render(view) =~ "Recent Feedback"
    end

    test "back navigation link works", %{conn: conn} do
      {:ok, solution} =
        create_solution(
          "Test problem for navigation",
          "This is a detailed solution pattern that helps solve the problem effectively"
        )

      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      assert has_element?(view, "a", "Back to Solutions")
      assert has_element?(view, "a[href='/solutions']")
    end

    test "redirects with flash when solution not found", %{conn: conn} do
      {:error, {:redirect, %{to: path, flash: flash}}} =
        live(conn, ~p"/solutions/00000000-0000-0000-0000-000000000000")

      assert path == "/solutions"
      assert flash["error"] == "Solution not found"
    end

    test "displays creation date", %{conn: conn} do
      {:ok, solution} =
        create_solution(
          "Test problem for date display",
          "This is a detailed solution pattern that helps solve the problem effectively"
        )

      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      # Should show creation date in format "January 30, 2026"
      html = render(view)
      assert html =~ "Created"
      # Date format check - will contain month name
      assert html =~ ~r/\w+ \d+, \d{4}/
    end

    test "handles solution with no tags", %{conn: conn} do
      {:ok, solution} =
        create_solution(
          "Test problem with no tags",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{}
        )

      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      # Should not show tags section
      refute render(view) =~ ~r/<div[^>]*>Tags<\/div>/
    end
  end

  defp create_solution(problem, solution, tags \\ %{}) do
    Solutions.create_solution(%{
      problem_description: problem,
      solution_pattern: solution,
      tags: tags
    })
  end
end
