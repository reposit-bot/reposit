defmodule RepositWeb.ModerationLiveTest do
  use RepositWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Reposit.AccountsFixtures

  alias Reposit.Solutions
  alias Reposit.Votes
  alias Reposit.Accounts.Scope

  describe "ModerationLive" do
    setup :register_and_log_in_admin

    setup do
      # Create users for voting
      voters = for i <- 1..5, do: user_fixture(%{email: "voter#{i}@example.com"})
      voter_scopes = Enum.map(voters, &Scope.for_user/1)
      solution_author = user_fixture(%{email: "author@example.com"})
      author_scope = Scope.for_user(solution_author)
      {:ok, voters: voters, voter_scopes: voter_scopes, solution_author: solution_author, author_scope: author_scope}
    end

    test "renders empty state when no flagged solutions", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/moderation")

      assert has_element?(view, "h1", "Moderation Queue")
      assert render(view) =~ "No flagged solutions"
    end

    test "shows flagged solutions with more downvotes than upvotes", %{
      conn: conn,
      voter_scopes: [voter_scope | _],
      author_scope: author_scope
    } do
      {:ok, solution} =
        create_solution(
          "Flagged problem description",
          "This is the solution that got flagged with downvotes",
          author_scope
        )

      # Add downvote to flag it
      {:ok, _} =
        Votes.create_vote(voter_scope, %{
          solution_id: solution.id,
          vote_type: :down,
          reason: :incorrect,
          comment: "This doesn't work at all"
        })

      {:ok, view, _html} = live(conn, ~p"/moderation")

      html = render(view)
      assert html =~ "Flagged problem description"
      assert html =~ "Incorrect"
    end

    test "shows flagged solutions with 3+ downvotes", %{
      conn: conn,
      voter_scopes: voter_scopes,
      author_scope: author_scope
    } do
      {:ok, solution} =
        create_solution(
          "Multi-downvote problem",
          "This solution got multiple downvotes from different agents",
          author_scope
        )

      # Update upvotes to make downvotes > upvotes condition not apply
      solution
      |> Ecto.Changeset.change(upvotes: 5)
      |> Reposit.Repo.update!()

      # Add 3 downvotes from different users
      for {voter_scope, i} <- Enum.with_index(Enum.take(voter_scopes, 3), 1) do
        {:ok, _} =
          Votes.create_vote(voter_scope, %{
            solution_id: solution.id,
            vote_type: :down,
            reason: :outdated,
            comment: "This is outdated #{i}"
          })
      end

      {:ok, view, _html} = live(conn, ~p"/moderation")

      html = render(view)
      assert html =~ "Multi-downvote problem"
    end

    test "does not show non-flagged solutions", %{
      conn: conn,
      voter_scopes: [voter_scope | _],
      author_scope: author_scope
    } do
      {:ok, good_solution} =
        create_solution(
          "Good solution problem here",
          "This is a good solution that everyone loves and finds very useful for their work",
          author_scope
        )

      # Add upvotes
      {:ok, _} =
        Votes.create_vote(voter_scope, %{
          solution_id: good_solution.id,
          vote_type: :up
        })

      {:ok, view, _html} = live(conn, ~p"/moderation")

      html = render(view)
      refute html =~ "Good solution problem"
      assert html =~ "No flagged solutions"
    end

    test "can filter by downvote reason", %{
      conn: conn,
      voter_scopes: [voter_scope1, voter_scope2 | _],
      author_scope: author_scope
    } do
      {:ok, solution1} =
        create_solution(
          "Incorrect solution problem here",
          "This solution is marked as incorrect and needs to be reviewed by the moderation team",
          author_scope
        )

      {:ok, solution2} =
        create_solution(
          "Outdated solution problem here",
          "This solution is marked as outdated and needs to be reviewed by the moderation team",
          author_scope
        )

      {:ok, _} =
        Votes.create_vote(voter_scope1, %{
          solution_id: solution1.id,
          vote_type: :down,
          reason: :incorrect,
          comment: "This is wrong"
        })

      {:ok, _} =
        Votes.create_vote(voter_scope2, %{
          solution_id: solution2.id,
          vote_type: :down,
          reason: :outdated,
          comment: "This is old"
        })

      {:ok, view, _html} = live(conn, ~p"/moderation")

      # Initially shows both
      html = render(view)
      assert html =~ "Incorrect solution problem"
      assert html =~ "Outdated solution problem"

      # Filter to incorrect only
      view
      |> element("select[name='reason']")
      |> render_change(%{reason: "incorrect"})

      html = render(view)
      assert html =~ "Incorrect solution problem"
      refute html =~ "Outdated solution problem"
    end

    test "approve action keeps solution in queue until page refresh", %{
      conn: conn,
      voter_scopes: [voter_scope | _],
      author_scope: author_scope
    } do
      {:ok, solution} =
        create_solution(
          "Solution that needs approval",
          "This solution will be approved by moderator after review of the content quality",
          author_scope
        )

      {:ok, _} =
        Votes.create_vote(voter_scope, %{
          solution_id: solution.id,
          vote_type: :down,
          reason: :incomplete,
          comment: "Missing some details"
        })

      {:ok, view, _html} = live(conn, ~p"/moderation")

      # Click approve (target the desktop table button with join-item class)
      view
      |> element("button.join-item", "Approve")
      |> render_click()

      # Should show flash
      assert has_element?(view, "[role='alert']")
    end

    test "archive action removes solution from queue", %{
      conn: conn,
      voter_scopes: [voter_scope | _],
      author_scope: author_scope
    } do
      {:ok, solution} =
        create_solution(
          "Solution that will be archived",
          "This solution will be archived by moderator after review of the reported issues",
          author_scope
        )

      {:ok, _} =
        Votes.create_vote(voter_scope, %{
          solution_id: solution.id,
          vote_type: :down,
          reason: :harmful,
          comment: "This could cause issues"
        })

      {:ok, view, _html} = live(conn, ~p"/moderation")

      # Verify solution is shown
      assert render(view) =~ "Solution that will be archived"

      # Click archive (target the desktop table button with join-item class)
      view
      |> element("button.join-item", "Archive")
      |> render_click()

      # Solution should be removed from queue
      html = render(view)
      refute html =~ "Solution that will be archived"
      assert html =~ "Solution archived"
    end

    test "archived solutions don't appear in moderation queue", %{
      conn: conn,
      voters: [voter | _],
      author_scope: author_scope
    } do
      {:ok, solution} =
        create_solution(
          "Already archived solution here",
          "This solution was already archived and should not appear in the moderation queue",
          author_scope
        )

      # Archive it first
      {:ok, _} = Solutions.archive_solution(solution.id)

      # Add downvote (wouldn't normally happen but testing the filter)
      Reposit.Repo.insert!(%Reposit.Votes.Vote{
        solution_id: solution.id,
        user_id: voter.id,
        vote_type: :down,
        reason: :incorrect,
        comment: "test comment"
      })

      {:ok, view, _html} = live(conn, ~p"/moderation")

      html = render(view)
      refute html =~ "Already archived solution"
    end

    test "displays feedback comments", %{
      conn: conn,
      voter_scopes: [voter_scope | _],
      author_scope: author_scope
    } do
      {:ok, solution} =
        create_solution(
          "Solution with feedback comments",
          "This solution has feedback from agents who have reviewed and tested the approach",
          author_scope
        )

      {:ok, _} =
        Votes.create_vote(voter_scope, %{
          solution_id: solution.id,
          vote_type: :down,
          reason: :incorrect,
          comment: "The algorithm complexity is wrong"
        })

      {:ok, view, _html} = live(conn, ~p"/moderation")

      html = render(view)
      assert html =~ "The algorithm complexity is wrong"
    end
  end

  defp create_solution(problem, solution, scope) do
    Solutions.create_solution(scope, %{
      problem_description: problem,
      solution_pattern: solution
    })
  end
end
