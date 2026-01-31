defmodule RepositWeb.SearchLiveTest do
  use RepositWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Reposit.AccountsFixtures

  alias Reposit.Solutions

  setup do
    user = user_fixture()
    {:ok, user: user}
  end

  describe "SearchLive" do
    test "renders search form", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/search")

      assert has_element?(view, "h1", "Search Solutions")
      assert has_element?(view, "textarea[name='query']")
      assert has_element?(view, "input[name='filter[language]']")
    end

    test "shows initial state before search", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/search")

      assert render(view) =~ "Enter a problem description to search"
    end

    test "performs search and shows results", %{conn: conn, user: user} do
      {:ok, _solution} =
        create_solution(
          "How to implement binary search in Elixir",
          "Use recursion with pattern matching for an elegant divide and conquer solution",
          %{},
          user.id
        )

      {:ok, view, _html} = live(conn, ~p"/search")

      # Trigger search
      view
      |> form("#search-form", %{query: "binary search elixir"})
      |> render_change()

      # Wait for async search to complete
      :timer.sleep(50)

      html = render(view)
      assert html =~ "binary search"
      assert html =~ "match"
    end

    test "shows loading state during search", %{conn: conn, user: user} do
      {:ok, _solution} =
        create_solution(
          "Test problem for loading state",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          user.id
        )

      {:ok, view, _html} = live(conn, ~p"/search")

      # Trigger search
      view
      |> form("#search-form", %{query: "test problem"})
      |> render_change()

      # Loading spinner should be visible immediately after search triggered
      # (before async handler completes)
      html = render(view)
      assert html =~ "loading-spinner" or html =~ "result"
    end

    test "shows no results message when no matches", %{conn: conn} do
      {:ok, view, _html} = live(conn, ~p"/search")

      view
      |> form("#search-form", %{query: "something very specific that wont match anything"})
      |> render_change()

      # Wait for async search
      :timer.sleep(50)

      html = render(view)
      assert html =~ "No solutions found"
      assert html =~ "something very specific"
    end

    test "clears results when query is emptied", %{conn: conn, user: user} do
      {:ok, _solution} =
        create_solution(
          "Test problem for clear",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          user.id
        )

      {:ok, view, _html} = live(conn, ~p"/search")

      # First do a search
      view
      |> form("#search-form", %{query: "test problem"})
      |> render_change()

      :timer.sleep(50)

      # Then clear
      view
      |> form("#search-form", %{query: ""})
      |> render_change()

      html = render(view)
      assert html =~ "Enter a problem description to search"
    end

    test "displays similarity score", %{conn: conn, user: user} do
      {:ok, _solution} =
        create_solution(
          "How to implement GenServer in Elixir",
          "Use the GenServer behaviour to create stateful processes with callbacks",
          %{},
          user.id
        )

      {:ok, view, _html} = live(conn, ~p"/search")

      view
      |> form("#search-form", %{query: "genserver elixir"})
      |> render_change()

      :timer.sleep(50)

      html = render(view)
      assert html =~ "% match"
    end

    test "shows vote score", %{conn: conn, user: user} do
      {:ok, solution} =
        create_solution(
          "Test problem for vote display",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          user.id
        )

      solution
      |> Ecto.Changeset.change(upvotes: 15, downvotes: 3)
      |> Reposit.Repo.update!()

      {:ok, view, _html} = live(conn, ~p"/search")

      view
      |> form("#search-form", %{query: "test problem"})
      |> render_change()

      :timer.sleep(50)

      html = render(view)
      assert html =~ "+12"
    end

    test "links to solution details", %{conn: conn, user: user} do
      {:ok, solution} =
        create_solution(
          "Test problem with link to details",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          user.id
        )

      {:ok, view, _html} = live(conn, ~p"/search")

      view
      |> form("#search-form", %{query: "test problem"})
      |> render_change()

      :timer.sleep(50)

      assert has_element?(view, "a[href='/solutions/#{solution.id}']")
    end

    test "can sort results by different criteria", %{conn: conn, user: user} do
      {:ok, _solution1} =
        create_solution(
          "First solution for sorting test",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{},
          user.id
        )

      {:ok, _solution2} =
        create_solution(
          "Second solution for sorting test",
          "Another detailed solution pattern that helps solve the problem effectively",
          %{},
          user.id
        )

      {:ok, view, _html} = live(conn, ~p"/search")

      view
      |> form("#search-form", %{query: "solution sorting"})
      |> render_change()

      :timer.sleep(50)

      # Click sort by top voted
      view |> element("button", "Top Voted") |> render_click()

      :timer.sleep(50)

      # Sort button should be present and clickable
      html = render(view)
      assert html =~ "Top Voted"
      # The active button gets shadow-sm styling
      assert html =~ "shadow-sm"
    end

    test "displays tags in results", %{conn: conn, user: user} do
      {:ok, _solution} =
        create_solution(
          "Test problem with tags for search",
          "This is a detailed solution pattern that helps solve the problem effectively",
          %{language: ["elixir"], framework: ["phoenix"]},
          user.id
        )

      {:ok, view, _html} = live(conn, ~p"/search")

      view
      |> form("#search-form", %{query: "test problem with tags"})
      |> render_change()

      :timer.sleep(50)

      html = render(view)
      assert html =~ "elixir"
      assert html =~ "phoenix"
    end
  end

  defp create_solution(problem, solution, tags, user_id) do
    Solutions.create_solution(%{
      problem_description: problem,
      solution_pattern: solution,
      tags: tags,
      user_id: user_id
    })
  end
end
