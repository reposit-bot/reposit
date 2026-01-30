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

  describe "GET /api/v1/solutions/search" do
    test "returns error when query is missing", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/solutions/search")

      assert %{
               "success" => false,
               "error" => "missing_query"
             } = json_response(conn, 400)
    end

    test "returns empty results when no solutions match", %{conn: conn} do
      conn = get(conn, ~p"/api/v1/solutions/search?q=nonexistent")

      assert %{
               "success" => true,
               "data" => %{
                 "results" => [],
                 "total" => 0
               }
             } = json_response(conn, 200)
    end

    test "returns matching solutions with similarity scores", %{conn: conn} do
      {:ok, _solution} = Solutions.create_solution(atomize_keys(@valid_attrs))

      conn = get(conn, ~p"/api/v1/solutions/search?q=binary+search")

      assert %{
               "success" => true,
               "data" => %{
                 "results" => [result],
                 "total" => 1
               }
             } = json_response(conn, 200)

      assert result["id"]
      assert result["problem_description"]
      assert result["similarity"]
      assert result["upvotes"] == 0
      assert result["downvotes"] == 0
    end

    test "respects limit parameter", %{conn: conn} do
      for i <- 1..5 do
        Solutions.create_solution(%{
          problem_description: "Problem #{i} - " <> String.duplicate("algorithm", 5),
          solution_pattern: @valid_attrs["solution_pattern"]
        })
      end

      conn = get(conn, ~p"/api/v1/solutions/search?q=algorithm&limit=2")

      assert %{
               "data" => %{
                 "results" => results,
                 "total" => 5
               }
             } = json_response(conn, 200)

      assert length(results) == 2
    end

    test "filters by required_tags", %{conn: conn} do
      {:ok, _s1} =
        Solutions.create_solution(%{
          problem_description: "How to implement binary search in Elixir",
          solution_pattern: @valid_attrs["solution_pattern"],
          tags: %{language: ["elixir"]}
        })

      {:ok, _s2} =
        Solutions.create_solution(%{
          problem_description: "How to implement binary search in Python",
          solution_pattern: @valid_attrs["solution_pattern"],
          tags: %{language: ["python"]}
        })

      conn = get(conn, ~p"/api/v1/solutions/search?q=binary+search&required_tags=language:elixir")

      assert %{
               "data" => %{
                 "results" => results
               }
             } = json_response(conn, 200)

      assert length(results) == 1
      assert hd(results)["tags"]["language"] == ["elixir"]
    end

    test "sorts by sort parameter", %{conn: conn} do
      {:ok, _} = Solutions.create_solution(atomize_keys(@valid_attrs))

      conn = get(conn, ~p"/api/v1/solutions/search?q=binary&sort=newest")

      assert %{"success" => true} = json_response(conn, 200)
    end
  end
end
