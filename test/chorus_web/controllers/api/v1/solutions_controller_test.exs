defmodule ChorusWeb.Api.V1.SolutionsControllerTest do
  use ChorusWeb.ConnCase, async: true

  alias Chorus.Solutions

  @valid_attrs %{
    "problem_description" => "How to implement binary search in Elixir efficiently",
    "solution_pattern" =>
      "Use recursion with pattern matching. Split the list in half and compare the middle element."
  }

  @invalid_attrs %{
    "problem_description" => "too short",
    "solution_pattern" => "too short"
  }

  describe "POST /api/v1/solutions" do
    test "creates solution and returns 201 with valid data", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/solutions", @valid_attrs)

      assert %{
               "success" => true,
               "data" => %{
                 "id" => id,
                 "problem_description" => "How to implement binary search in Elixir efficiently",
                 "solution_pattern" =>
                   "Use recursion with pattern matching. Split the list in half and compare the middle element.",
                 "upvotes" => 0,
                 "downvotes" => 0,
                 "score" => 0
               }
             } = json_response(conn, 201)

      assert is_binary(id)
    end

    test "returns 422 with validation errors for invalid data", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/solutions", @invalid_attrs)

      assert %{
               "success" => false,
               "error" => "validation_failed",
               "hint" => hint
             } = json_response(conn, 422)

      assert hint =~ "problem_description"
      assert hint =~ "solution_pattern"
    end

    test "returns 422 when problem_description is missing", %{conn: conn} do
      attrs = Map.delete(@valid_attrs, "problem_description")
      conn = post(conn, ~p"/api/v1/solutions", attrs)

      assert %{
               "success" => false,
               "error" => "validation_failed"
             } = json_response(conn, 422)
    end

    test "creates solution with tags", %{conn: conn} do
      attrs =
        Map.put(@valid_attrs, "tags", %{
          "language" => ["elixir"],
          "framework" => ["phoenix"]
        })

      conn = post(conn, ~p"/api/v1/solutions", attrs)

      assert %{
               "success" => true,
               "data" => %{
                 "tags" => %{
                   "language" => ["elixir"],
                   "framework" => ["phoenix"]
                 }
               }
             } = json_response(conn, 201)
    end
  end

  describe "GET /api/v1/solutions/:id" do
    test "returns solution when found", %{conn: conn} do
      {:ok, solution} = Solutions.create_solution(atomize_keys(@valid_attrs))

      conn = get(conn, ~p"/api/v1/solutions/#{solution.id}")

      assert %{
               "success" => true,
               "data" => %{
                 "id" => id,
                 "problem_description" => "How to implement binary search in Elixir efficiently"
               }
             } = json_response(conn, 200)

      assert id == solution.id
    end

    test "returns 404 when not found", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/solutions/#{Ecto.UUID.generate()}")

      assert %{
               "success" => false,
               "error" => "not_found"
             } = json_response(conn, 404)
    end
  end

  defp atomize_keys(map) do
    Map.new(map, fn {k, v} -> {String.to_atom(k), v} end)
  end
end
