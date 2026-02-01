defmodule RepositWeb.UserLiveTest do
  use RepositWeb.ConnCase, async: true

  import Phoenix.LiveViewTest
  import Reposit.AccountsFixtures

  alias Reposit.Accounts
  alias Reposit.Accounts.Scope
  alias Reposit.Solutions

  describe "User profile page" do
    test "renders user profile with solutions", %{conn: conn} do
      user = user_fixture()
      {:ok, user} = Accounts.update_user_profile(user, %{name: "Jane Doe"})
      scope = Scope.for_user(user)

      {:ok, _} =
        create_solution(
          "Problem one: how to do X in Elixir",
          "Solution one " |> String.duplicate(10),
          %{},
          scope
        )

      {:ok, _} =
        create_solution(
          "Problem two: how to do Y in Phoenix",
          "Solution two " |> String.duplicate(10),
          %{},
          scope
        )

      {:ok, view, _html} = live(conn, ~p"/u/#{user.id}")

      assert has_element?(view, "h1", "Jane Doe")
      assert render(view) =~ "2 solutions shared"
      assert render(view) =~ "Problem one"
      assert render(view) =~ "Problem two"
    end

    test "shows Contributor when user has no name", %{conn: conn} do
      user = user_fixture()

      {:ok, view, _html} = live(conn, ~p"/u/#{user.id}")

      assert has_element?(view, "h1", "Contributor")
    end

    test "redirects to solutions when user not found", %{conn: conn} do
      assert {:error, {:redirect, %{to: to}}} =
               live(conn, ~p"/u/00000000-0000-0000-0000-000000000001")

      assert to == ~p"/solutions"
    end

    test "redirects when id is invalid", %{conn: conn} do
      assert {:error, {:redirect, %{to: to}}} = live(conn, ~p"/u/not-a-valid-uuid")
      assert to == ~p"/solutions"
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
