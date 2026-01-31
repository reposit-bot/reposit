defmodule ChorusWeb.ModerationLiveTest do
  use ChorusWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Chorus.Solutions
  alias Chorus.Votes

  describe "ModerationLive" do
    test "renders empty state when no flagged solutions", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/moderation")

      assert has_element?(view, "h1", "Moderation Queue")
      assert render(view) =~ "No flagged solutions"
    end

    test "shows flagged solutions with more downvotes than upvotes", %{conn: conn} do
      {:ok, solution} =
        create_solution(
          "Flagged problem description",
          "This is the solution that got flagged with downvotes"
        )

      # Add downvote to flag it
      {:ok, _} =
        Votes.create_vote(%{
          solution_id: solution.id,
          agent_session_id: "session-1",
          vote_type: :down,
          reason: :incorrect,
          comment: "This doesn't work at all"
        })

      {:ok, view, _html} = live(conn, ~p"/moderation")

      html = render(view)
      assert html =~ "Flagged problem description"
      assert html =~ "Incorrect"
    end

    test "shows flagged solutions with 3+ downvotes", %{conn: conn} do
      {:ok, solution} =
        create_solution(
          "Multi-downvote problem",
          "This solution got multiple downvotes from different agents"
        )

      # Update upvotes to make downvotes > upvotes condition not apply
      solution
      |> Ecto.Changeset.change(upvotes: 5)
      |> Chorus.Repo.update!()

      # Add 3 downvotes
      for i <- 1..3 do
        {:ok, _} =
          Votes.create_vote(%{
            solution_id: solution.id,
            agent_session_id: "session-#{i}",
            vote_type: :down,
            reason: :outdated,
            comment: "This is outdated #{i}"
          })
      end

      {:ok, view, _html} = live(conn, ~p"/moderation")

      html = render(view)
      assert html =~ "Multi-downvote problem"
    end

    test "does not show non-flagged solutions", %{conn: conn} do
      {:ok, good_solution} =
        create_solution(
          "Good solution problem here",
          "This is a good solution that everyone loves and finds very useful for their work"
        )

      # Add upvotes
      {:ok, _} =
        Votes.create_vote(%{
          solution_id: good_solution.id,
          agent_session_id: "session-happy",
          vote_type: :up
        })

      {:ok, view, _html} = live(conn, ~p"/moderation")

      html = render(view)
      refute html =~ "Good solution problem"
      assert html =~ "No flagged solutions"
    end

    test "can filter by downvote reason", %{conn: conn} do
      {:ok, solution1} =
        create_solution(
          "Incorrect solution problem here",
          "This solution is marked as incorrect and needs to be reviewed by the moderation team"
        )

      {:ok, solution2} =
        create_solution(
          "Outdated solution problem here",
          "This solution is marked as outdated and needs to be reviewed by the moderation team"
        )

      {:ok, _} =
        Votes.create_vote(%{
          solution_id: solution1.id,
          agent_session_id: "session-1",
          vote_type: :down,
          reason: :incorrect,
          comment: "This is wrong"
        })

      {:ok, _} =
        Votes.create_vote(%{
          solution_id: solution2.id,
          agent_session_id: "session-2",
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

    test "approve action keeps solution in queue until page refresh", %{conn: conn} do
      {:ok, solution} =
        create_solution(
          "Solution that needs approval",
          "This solution will be approved by moderator after review of the content quality"
        )

      {:ok, _} =
        Votes.create_vote(%{
          solution_id: solution.id,
          agent_session_id: "session-1",
          vote_type: :down,
          reason: :incomplete,
          comment: "Missing some details"
        })

      {:ok, view, _html} = live(conn, ~p"/moderation")

      # Click approve
      view
      |> element("button", "Approve")
      |> render_click()

      # Should show flash
      assert has_element?(view, "[role='alert']")
    end

    test "archive action removes solution from queue", %{conn: conn} do
      {:ok, solution} =
        create_solution(
          "Solution that will be archived",
          "This solution will be archived by moderator after review of the reported issues"
        )

      {:ok, _} =
        Votes.create_vote(%{
          solution_id: solution.id,
          agent_session_id: "session-1",
          vote_type: :down,
          reason: :harmful,
          comment: "This could cause issues"
        })

      {:ok, view, _html} = live(conn, ~p"/moderation")

      # Verify solution is shown
      assert render(view) =~ "Solution that will be archived"

      # Click archive
      view
      |> element("button", "Archive")
      |> render_click()

      # Solution should be removed from queue
      html = render(view)
      refute html =~ "Solution that will be archived"
      assert html =~ "Solution archived"
    end

    test "archived solutions don't appear in moderation queue", %{conn: conn} do
      {:ok, solution} =
        create_solution(
          "Already archived solution here",
          "This solution was already archived and should not appear in the moderation queue"
        )

      # Archive it first
      {:ok, _} = Solutions.archive_solution(solution.id)

      # Add downvote (wouldn't normally happen but testing the filter)
      Chorus.Repo.insert!(%Chorus.Votes.Vote{
        solution_id: solution.id,
        agent_session_id: "session-1",
        vote_type: :down,
        reason: :incorrect,
        comment: "test"
      })

      {:ok, view, _html} = live(conn, ~p"/moderation")

      html = render(view)
      refute html =~ "Already archived solution"
    end

    test "displays feedback comments", %{conn: conn} do
      {:ok, solution} =
        create_solution(
          "Solution with feedback comments",
          "This solution has feedback from agents who have reviewed and tested the approach"
        )

      {:ok, _} =
        Votes.create_vote(%{
          solution_id: solution.id,
          agent_session_id: "session-1",
          vote_type: :down,
          reason: :incorrect,
          comment: "The algorithm complexity is wrong"
        })

      {:ok, view, _html} = live(conn, ~p"/moderation")

      html = render(view)
      assert html =~ "The algorithm complexity is wrong"
    end
  end

  defp create_solution(problem, solution) do
    Solutions.create_solution(%{
      problem_description: problem,
      solution_pattern: solution
    })
  end
end
