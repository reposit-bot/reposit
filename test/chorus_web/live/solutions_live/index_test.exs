defmodule ChorusWeb.SolutionsLive.IndexTest do
  use ChorusWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias Chorus.Solutions

  describe "Index" do
    test "renders empty state when no solutions exist", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/solutions")

      assert has_element?(view, "h1", "Solutions")
      assert has_element?(view, "p", "0 solutions shared by the community")
      assert has_element?(view, "p", "No solutions yet")
    end

    test "renders solutions list", %{conn: conn} do
      {:ok, _solution} = create_solution("Test problem description here", "This is a detailed solution pattern that helps solve the problem effectively")

      {:ok, view, _html} = live(conn, ~p"/solutions")

      assert has_element?(view, "h1", "Solutions")
      assert has_element?(view, "p", "1 solution shared by the community")
      assert render(view) =~ "Test problem description here"
    end

    test "displays tags as badges", %{conn: conn} do
      {:ok, _solution} = create_solution(
        "Test problem with tags here",
        "This is a detailed solution pattern that helps solve the problem effectively",
        %{language: ["elixir"], framework: ["phoenix"]}
      )

      {:ok, view, _html} = live(conn, ~p"/solutions")

      html = render(view)
      assert html =~ "elixir"
      assert html =~ "phoenix"
      assert html =~ "badge"
    end

    test "displays vote counts", %{conn: conn} do
      {:ok, solution} = create_solution("Test problem for voting", "This is a detailed solution pattern that helps solve the problem effectively")

      # Manually update vote counts for testing display
      solution
      |> Ecto.Changeset.change(upvotes: 10, downvotes: 2)
      |> Chorus.Repo.update!()

      {:ok, view, _html} = live(conn, ~p"/solutions")

      html = render(view)
      assert html =~ "10"
      assert html =~ "2"
      assert html =~ "(+8)"
    end

    test "sorts by score by default", %{conn: conn} do
      {:ok, low_score} = create_solution("Low score problem desc", "This is a detailed solution pattern that helps solve the problem effectively")
      {:ok, high_score} = create_solution("High score problem desc", "Another detailed solution pattern that helps solve the problem effectively")

      Ecto.Changeset.change(low_score, upvotes: 5, downvotes: 3)
      |> Chorus.Repo.update!()

      Ecto.Changeset.change(high_score, upvotes: 20, downvotes: 1)
      |> Chorus.Repo.update!()

      {:ok, view, _html} = live(conn, ~p"/solutions")

      # High score should appear first
      html = render(view)
      high_pos = :binary.match(html, "High score problem desc")
      low_pos = :binary.match(html, "Low score problem desc")

      assert elem(high_pos, 0) < elem(low_pos, 0)
    end

    test "can sort by newest", %{conn: conn} do
      {:ok, _older} = create_solution("Older problem description", "This is a detailed solution pattern that helps solve the problem effectively")
      Process.sleep(10)
      {:ok, _newer} = create_solution("Newer problem description", "Another detailed solution pattern that helps solve the problem effectively")

      {:ok, view, _html} = live(conn, ~p"/solutions")

      # Click newest sort
      view |> element("button", "Newest") |> render_click()

      # Verify URL changed
      assert_patch(view, ~p"/solutions?sort=newest&page=1")

      # Newer should appear first
      html = render(view)
      newer_pos = :binary.match(html, "Newer problem description")
      older_pos = :binary.match(html, "Older problem description")

      assert elem(newer_pos, 0) < elem(older_pos, 0)
    end

    test "can sort by votes", %{conn: conn} do
      {:ok, low_votes} = create_solution("Low votes problem desc", "This is a detailed solution pattern that helps solve the problem effectively")
      {:ok, high_votes} = create_solution("High votes problem desc", "Another detailed solution pattern that helps solve the problem effectively")

      Ecto.Changeset.change(low_votes, upvotes: 5)
      |> Chorus.Repo.update!()

      Ecto.Changeset.change(high_votes, upvotes: 50)
      |> Chorus.Repo.update!()

      {:ok, view, _html} = live(conn, ~p"/solutions")

      view |> element("button", "Votes") |> render_click()

      assert_patch(view, ~p"/solutions?sort=votes&page=1")

      html = render(view)
      high_pos = :binary.match(html, "High votes problem desc")
      low_pos = :binary.match(html, "Low votes problem desc")

      assert elem(high_pos, 0) < elem(low_pos, 0)
    end

    test "pagination works correctly", %{conn: conn} do
      # Create more than one page of solutions (12 per page)
      for i <- 1..15 do
        create_solution("Problem number #{i} description", "This is a detailed solution pattern number #{i} that helps solve the problem")
      end

      {:ok, view, _html} = live(conn, ~p"/solutions")

      # Should show page 1 of 2
      html = render(view)
      assert html =~ "Page 1 of 2"
      assert has_element?(view, "a", "Next")
      refute has_element?(view, "a", "Previous")

      # Navigate to page 2
      view |> element("a", "Next") |> render_click()

      assert_patch(view, ~p"/solutions?page=2&sort=score")

      html = render(view)
      assert html =~ "Page 2 of 2"
      assert has_element?(view, "a", "Previous")
      refute has_element?(view, "a", "Next")
    end

    test "handles invalid page param gracefully", %{conn: conn} do
      # Create enough solutions to have multiple pages
      for i <- 1..15 do
        create_solution("Problem number #{i} description", "This is a detailed solution pattern number #{i} that helps solve the problem")
      end

      {:ok, view, _html} = live(conn, ~p"/solutions?page=invalid")

      # Should default to page 1
      html = render(view)
      assert html =~ "Page 1 of 2"
    end

    test "handles invalid sort param gracefully", %{conn: conn} do
      {:ok, _} = create_solution("Test problem description", "This is a detailed solution pattern that helps solve the problem effectively")

      {:ok, view, _html} = live(conn, ~p"/solutions?sort=invalid")

      # Should default to score sort and show the Score button as active
      assert has_element?(view, "button.btn-primary", "Score")
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
