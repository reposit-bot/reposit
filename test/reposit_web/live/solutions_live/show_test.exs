defmodule RepositWeb.SolutionsLive.ShowTest do
  use RepositWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Reposit.AccountsFixtures

  alias Reposit.Solutions
  alias Reposit.Votes
  alias Reposit.Accounts.Scope

  setup do
    user = user_fixture()
    voter = user_fixture()
    user_scope = Scope.for_user(user)
    voter_scope = Scope.for_user(voter)
    {:ok, user: user, voter: voter, user_scope: user_scope, voter_scope: voter_scope}
  end

  describe "Show" do
    test "renders solution details", %{conn: conn, user_scope: user_scope} do
      {:ok, solution} =
        create_solution(
          "How to implement binary search in Elixir",
          "Use recursion with pattern matching for an elegant solution. Here's the approach:\n\n1. Check middle element\n2. Recurse left or right",
          %{},
          user_scope
        )

      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      # Problem description is shown in the page content
      assert render(view) =~ "How to implement binary search in Elixir"
      assert render(view) =~ "Use recursion with pattern matching"
    end

    test "renders markdown content", %{conn: conn, user_scope: user_scope} do
      {:ok, solution} =
        create_solution(
          "Test problem for markdown rendering",
          "Here is some **bold** text and *italic* text. This needs to be at least fifty characters long.",
          %{},
          user_scope
        )

      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      html = render(view)
      assert html =~ "<strong>bold</strong>"
      assert html =~ "<em>italic</em>"
    end

    test "displays tags grouped by category", %{conn: conn, user_scope: user_scope} do
      {:ok, solution} =
        create_solution(
          "Test problem with multiple tags",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{
            language: ["elixir", "erlang"],
            framework: ["phoenix"],
            domain: ["api", "web"]
          },
          user_scope
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

    test "displays vote stats", %{conn: conn, user_scope: user_scope} do
      {:ok, solution} =
        create_solution(
          "Test problem for vote display",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          user_scope
        )

      # Update vote counts
      solution
      |> Ecto.Changeset.change(upvotes: 25, downvotes: 5)
      |> Reposit.Repo.update!()

      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      html = render(view)
      # Check vote display - shows upvotes, downvotes, and score
      assert html =~ "25"
      assert html =~ "5"
      assert html =~ "+20"
    end

    test "displays upvote percentage in radial progress", %{conn: conn, user_scope: user_scope} do
      {:ok, solution} =
        create_solution(
          "Test problem for percentage",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          user_scope
        )

      # 75% upvote rate (15 up, 5 down)
      solution
      |> Ecto.Changeset.change(upvotes: 15, downvotes: 5)
      |> Reposit.Repo.update!()

      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      html = render(view)
      assert html =~ "75%"
    end

    test "displays vote comments from downvotes", %{
      conn: conn,
      user_scope: user_scope,
      voter_scope: voter_scope
    } do
      {:ok, solution} =
        create_solution(
          "Test problem for vote comments",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          user_scope
        )

      # Create a downvote with comment
      {:ok, _vote} =
        Votes.create_vote(voter_scope, %{
          solution_id: solution.id,
          vote_type: :down,
          comment: "This approach is deprecated since Phoenix 1.7",
          reason: :outdated
        })

      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      html = render(view)
      assert html =~ "This approach is deprecated since Phoenix 1.7"
      assert html =~ "Outdated"
    end

    test "does not display upvote comments (they don't have any)", %{
      conn: conn,
      user_scope: user_scope,
      voter_scope: voter_scope
    } do
      {:ok, solution} =
        create_solution(
          "Test problem for upvote display",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          user_scope
        )

      # Create an upvote (no comment)
      {:ok, _vote} =
        Votes.create_vote(voter_scope, %{
          solution_id: solution.id,
          vote_type: :up
        })

      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      # Should not have the feedback section with no comments
      refute render(view) =~ "Recent Feedback"
    end

    test "back navigation link works", %{conn: conn, user_scope: user_scope} do
      {:ok, solution} =
        create_solution(
          "Test problem for navigation",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          user_scope
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

    test "displays creation date", %{conn: conn, user_scope: user_scope} do
      {:ok, solution} =
        create_solution(
          "Test problem for date display",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          user_scope
        )

      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      # Should show creation date in format "January 30, 2026"
      html = render(view)
      assert html =~ "Created"
      # Date format check - will contain month name
      assert html =~ ~r/\w+ \d+, \d{4}/
    end

    test "handles solution with no tags", %{conn: conn, user_scope: user_scope} do
      {:ok, solution} =
        create_solution(
          "Test problem with no tags",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          user_scope
        )

      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      # Should not show tags section
      refute render(view) =~ ~r/<div[^>]*>Tags<\/div>/
    end
  end

  describe "delete solution" do
    test "author sees delete button", %{conn: conn, user: user, user_scope: user_scope} do
      {:ok, solution} =
        create_solution(
          "Test problem for delete",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          user_scope
        )

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      assert has_element?(view, "button[phx-click='show-delete-confirm']")
    end

    test "non-author does not see delete button", %{
      conn: conn,
      user_scope: user_scope,
      voter: other_user
    } do
      {:ok, solution} =
        create_solution(
          "Test problem for delete visibility",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          user_scope
        )

      conn = log_in_user(conn, other_user)
      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      refute has_element?(view, "button[phx-click='show-delete-confirm']")
    end

    test "guest does not see delete button", %{conn: conn, user_scope: user_scope} do
      {:ok, solution} =
        create_solution(
          "Test problem for guest delete",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          user_scope
        )

      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      refute has_element?(view, "button[phx-click='show-delete-confirm']")
    end

    test "author can delete their solution", %{conn: conn, user: user, user_scope: user_scope} do
      {:ok, solution} =
        create_solution(
          "Test problem to delete",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          user_scope
        )

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      # Click delete button to show confirmation
      view |> element("button[phx-click='show-delete-confirm']") |> render_click()

      # Confirmation modal should appear
      assert render(view) =~ "Delete this solution?"

      # Confirm delete
      view |> element("button[phx-click='delete-solution']") |> render_click()

      # Should redirect to solutions list
      assert_redirect(view, "/solutions")

      # Solution should be deleted
      assert {:error, :not_found} = Solutions.get_solution(solution.id)
    end

    test "can cancel delete", %{conn: conn, user: user, user_scope: user_scope} do
      {:ok, solution} =
        create_solution(
          "Test problem for cancel delete",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          user_scope
        )

      conn = log_in_user(conn, user)
      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      # Show confirmation
      view |> element("button[phx-click='show-delete-confirm']") |> render_click()
      assert render(view) =~ "Delete this solution?"

      # Cancel
      view |> element("button[phx-click='cancel-delete']") |> render_click()

      # Modal should be gone
      refute render(view) =~ "Delete this solution?"

      # Solution should still exist
      assert {:ok, _} = Solutions.get_solution(solution.id)
    end
  end

  describe "voting" do
    test "shows login prompt for guests", %{conn: conn, user_scope: user_scope} do
      {:ok, solution} =
        create_solution(
          "Test problem for guest voting",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          user_scope
        )

      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      html = render(view)
      assert html =~ "Log in"
      assert html =~ "to vote"
    end

    test "logged in user can upvote", %{conn: conn, user_scope: user_scope, voter: voter} do
      {:ok, solution} =
        create_solution(
          "Test problem for upvoting",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          user_scope
        )

      conn = log_in_user(conn, voter)
      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      # Click upvote
      view |> element("button[phx-click='upvote']") |> render_click()

      # Vote count should increase
      html = render(view)
      assert html =~ ">1</span>"
    end

    test "logged in user can downvote with comment", %{
      conn: conn,
      user_scope: user_scope,
      voter: voter
    } do
      {:ok, solution} =
        create_solution(
          "Test problem for downvoting",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          user_scope
        )

      conn = log_in_user(conn, voter)
      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      # Click to show downvote form
      view |> element("button[phx-click='show-downvote-form']") |> render_click()

      # Form should be visible
      html = render(view)
      assert html =~ "Why are you downvoting?"

      # Submit downvote
      view
      |> form("form[phx-submit='downvote']", %{
        comment: "This solution has issues with edge cases",
        reason: "incorrect"
      })
      |> render_submit()

      # Downvote count should increase
      html = render(view)
      assert html =~ ">1</span>"
    end

    test "user can change vote from up to down", %{
      conn: conn,
      user_scope: user_scope,
      voter: voter
    } do
      {:ok, solution} =
        create_solution(
          "Test problem for changing vote",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          user_scope
        )

      conn = log_in_user(conn, voter)
      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      # First upvote
      view |> element("button[phx-click='upvote']") |> render_click()

      # Then change to downvote
      view |> element("button[phx-click='show-downvote-form']") |> render_click()

      view
      |> form("form[phx-submit='downvote']", %{
        comment: "Changed my mind, this has issues",
        reason: "incorrect"
      })
      |> render_submit()

      # Should now have 0 upvotes and 1 downvote
      {:ok, updated_solution} = Solutions.get_solution(solution.id)
      assert updated_solution.upvotes == 0
      assert updated_solution.downvotes == 1
    end

    test "user can remove their upvote", %{
      conn: conn,
      user_scope: user_scope,
      voter: voter,
      voter_scope: voter_scope
    } do
      {:ok, solution} =
        create_solution(
          "Test problem for removing upvote",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          user_scope
        )

      # Create an upvote
      {:ok, _} = Votes.create_vote(voter_scope, %{solution_id: solution.id, vote_type: :up})

      conn = log_in_user(conn, voter)
      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      # Should see remove vote button
      assert has_element?(view, "button[phx-click='remove-vote']")

      # Remove the vote
      view |> element("button[phx-click='remove-vote']") |> render_click()

      # Vote should be removed - no more remove button
      refute has_element?(view, "button[phx-click='remove-vote']")

      # Solution counts should be updated
      {:ok, updated} = Solutions.get_solution(solution.id)
      assert updated.upvotes == 0
    end

    test "user can remove their downvote", %{
      conn: conn,
      user_scope: user_scope,
      voter: voter,
      voter_scope: voter_scope
    } do
      {:ok, solution} =
        create_solution(
          "Test problem for removing downvote",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          user_scope
        )

      # Create a downvote
      {:ok, _} =
        Votes.create_vote(voter_scope, %{
          solution_id: solution.id,
          vote_type: :down,
          comment: "This has issues with the approach",
          reason: :incorrect
        })

      conn = log_in_user(conn, voter)
      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      # Remove the vote
      view |> element("button[phx-click='remove-vote']") |> render_click()

      # Solution counts should be updated
      {:ok, updated} = Solutions.get_solution(solution.id)
      assert updated.downvotes == 0
    end

    test "remove vote button not shown when no vote", %{
      conn: conn,
      user_scope: user_scope,
      voter: voter
    } do
      {:ok, solution} =
        create_solution(
          "Test problem for no vote",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          user_scope
        )

      conn = log_in_user(conn, voter)
      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      # Should not see remove vote button
      refute has_element?(view, "button[phx-click='remove-vote']")
    end

    test "shows user's existing vote", %{
      conn: conn,
      user_scope: user_scope,
      voter: voter,
      voter_scope: voter_scope
    } do
      {:ok, solution} =
        create_solution(
          "Test problem for existing vote",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          user_scope
        )

      # Create an existing upvote
      {:ok, _vote} =
        Votes.create_vote(voter_scope, %{
          solution_id: solution.id,
          vote_type: :up
        })

      conn = log_in_user(conn, voter)
      {:ok, view, _html} = live(conn, ~p"/solutions/#{solution.id}")

      # Upvote button should have active styling (ring-2)
      html = render(view)
      assert html =~ "ring-2 ring-[oklch(55%_0.15_145)]"
    end
  end

  defp create_solution(problem, solution, tags, scope) do
    Solutions.create_solution(scope, %{
      problem_description: problem,
      solution_pattern: solution,
      tags: tags
    })
  end
end
