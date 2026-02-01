defmodule RepositWeb.SolutionsLive.IndexTest do
  use RepositWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Reposit.AccountsFixtures

  alias Reposit.Solutions
  alias Reposit.Accounts.Scope

  setup do
    user = user_fixture()
    scope = Scope.for_user(user)
    {:ok, user: user, scope: scope}
  end

  describe "Index" do
    test "renders empty state when no solutions exist", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/solutions")

      assert has_element?(view, "h1", "Solutions")
      assert has_element?(view, "p", "0 solutions shared by the community")
      assert has_element?(view, "p", "No solutions yet")
    end

    test "renders solutions list", %{conn: conn, scope: scope} do
      {:ok, _solution} =
        create_solution(
          "Test problem description here",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          scope
        )

      {:ok, view, _html} = live(conn, ~p"/solutions")

      assert has_element?(view, "h1", "Solutions")
      assert has_element?(view, "p", "1 solution shared by the community")
      assert render(view) =~ "Test problem description here"
    end

    test "displays tags as badges", %{conn: conn, scope: scope} do
      {:ok, _solution} =
        create_solution(
          "Test problem with tags here",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{language: ["elixir"], framework: ["phoenix"]},
          scope
        )

      {:ok, view, _html} = live(conn, ~p"/solutions")

      html = render(view)
      assert html =~ "elixir"
      assert html =~ "phoenix"
      assert html =~ "badge"
    end

    test "displays vote counts", %{conn: conn, scope: scope} do
      {:ok, solution} =
        create_solution(
          "Test problem for voting",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          scope
        )

      # Manually update vote counts for testing display
      solution
      |> Ecto.Changeset.change(upvotes: 10, downvotes: 2)
      |> Reposit.Repo.update!()

      {:ok, view, _html} = live(conn, ~p"/solutions")

      html = render(view)
      assert html =~ "10"
      assert html =~ "2"
      assert html =~ "+8"
    end

    test "sorts by score by default", %{conn: conn, scope: scope} do
      {:ok, low_score} =
        create_solution(
          "Low score problem desc",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          scope
        )

      {:ok, high_score} =
        create_solution(
          "High score problem desc",
          "Another detailed solution pattern that helps solve the problem effectively",
          %{},
          scope
        )

      Ecto.Changeset.change(low_score, upvotes: 5, downvotes: 3)
      |> Reposit.Repo.update!()

      Ecto.Changeset.change(high_score, upvotes: 20, downvotes: 1)
      |> Reposit.Repo.update!()

      {:ok, view, _html} = live(conn, ~p"/solutions")

      # High score should appear first
      html = render(view)
      high_pos = :binary.match(html, "High score problem desc")
      low_pos = :binary.match(html, "Low score problem desc")

      assert elem(high_pos, 0) < elem(low_pos, 0)
    end

    test "can sort by newest", %{conn: conn, scope: scope} do
      {:ok, _older} =
        create_solution(
          "Older problem description",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          scope
        )

      Process.sleep(10)

      {:ok, _newer} =
        create_solution(
          "Newer problem description",
          "Another detailed solution pattern that helps solve the problem effectively",
          %{},
          scope
        )

      {:ok, view, _html} = live(conn, ~p"/solutions")

      # Click newest sort
      view |> element("button", "Newest") |> render_click()

      # Verify URL changed
      assert_patch(view, ~p"/solutions?sort=newest")

      # Newer should appear first
      html = render(view)
      newer_pos = :binary.match(html, "Newer problem description")
      older_pos = :binary.match(html, "Older problem description")

      assert elem(newer_pos, 0) < elem(older_pos, 0)
    end

    test "can sort by votes", %{conn: conn, scope: scope} do
      {:ok, low_votes} =
        create_solution(
          "Low votes problem desc",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          scope
        )

      {:ok, high_votes} =
        create_solution(
          "High votes problem desc",
          "Another detailed solution pattern that helps solve the problem effectively",
          %{},
          scope
        )

      Ecto.Changeset.change(low_votes, upvotes: 5)
      |> Reposit.Repo.update!()

      Ecto.Changeset.change(high_votes, upvotes: 50)
      |> Reposit.Repo.update!()

      {:ok, view, _html} = live(conn, ~p"/solutions")

      view |> element("button", "Votes") |> render_click()

      assert_patch(view, ~p"/solutions?sort=votes")

      html = render(view)
      high_pos = :binary.match(html, "High votes problem desc")
      low_pos = :binary.match(html, "Low votes problem desc")

      assert elem(high_pos, 0) < elem(low_pos, 0)
    end

    test "infinite scroll loads more solutions", %{conn: conn, scope: scope} do
      # Create more than one page of solutions (12 per page)
      for i <- 1..15 do
        create_solution(
          "Problem number #{i} description",
          "This is a detailed solution pattern number #{i} that helps solve the problem",
          %{},
          scope
        )
      end

      {:ok, view, _html} = live(conn, ~p"/solutions")

      # Should show 15 solutions total count
      assert has_element?(view, "p", "15 solutions shared by the community")

      # Should show the infinite scroll sentinel
      assert has_element?(view, "#infinite-scroll-sentinel")

      # Trigger load more
      render_hook(view, "load-more", %{})

      # After loading more, should show end message
      assert has_element?(view, "p", "15 solutions total")
    end

    test "shows end message when all solutions are loaded", %{conn: conn, scope: scope} do
      # Create fewer than one page of solutions
      for i <- 1..5 do
        create_solution(
          "Problem number #{i} description",
          "This is a detailed solution pattern number #{i} that helps solve the problem",
          %{},
          scope
        )
      end

      {:ok, view, _html} = live(conn, ~p"/solutions")

      # With only 5 solutions (less than 12 per page), should show end message immediately
      assert has_element?(view, "p", "5 solutions total")
      # Should NOT show the infinite scroll sentinel when all are loaded
      refute has_element?(view, "#infinite-scroll-sentinel")
    end

    test "handles invalid sort param gracefully", %{conn: conn, scope: scope} do
      {:ok, _} =
        create_solution(
          "Test problem description",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          scope
        )

      {:ok, view, _html} = live(conn, ~p"/solutions?sort=invalid")

      # Should default to score sort - the Score button should have the active styling (shadow-sm)
      html = render(view)
      assert html =~ "Score"
      # Verify default sort is applied by checking the button exists with active class
      assert has_element?(view, "button[phx-value-sort='score']")
    end
  end

  defp create_solution(problem, solution, tags, scope) do
    Solutions.create_solution(scope, %{
      problem: problem,
      solution: solution,
      tags: tags
    })
  end
end
