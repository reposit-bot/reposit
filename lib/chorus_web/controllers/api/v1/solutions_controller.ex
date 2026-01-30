defmodule ChorusWeb.Api.V1.SolutionsController do
  use ChorusWeb, :controller

  alias Chorus.Solutions
  alias Chorus.Solutions.Solution

  action_fallback ChorusWeb.Api.V1.FallbackController

  @doc """
  Creates a new solution.

  POST /api/v1/solutions
  """
  def create(conn, params) do
    case Solutions.create_solution(params) do
      {:ok, solution} ->
        conn
        |> put_status(:created)
        |> json(%{
          success: true,
          data: solution_json(solution)
        })

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{
          success: false,
          error: "validation_failed",
          hint: format_changeset_errors(changeset)
        })
    end
  end

  @doc """
  Gets a single solution by ID.

  GET /api/v1/solutions/:id
  """
  def show(conn, %{"id" => id}) do
    case Solutions.get_solution(id) do
      {:ok, solution} ->
        json(conn, %{
          success: true,
          data: solution_json(solution)
        })

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{
          success: false,
          error: "not_found",
          hint: "Solution with ID #{id} not found"
        })
    end
  end

  defp solution_json(%Solution{} = solution) do
    %{
      id: solution.id,
      problem_description: solution.problem_description,
      solution_pattern: solution.solution_pattern,
      context_requirements: solution.context_requirements,
      tags: solution.tags,
      upvotes: solution.upvotes,
      downvotes: solution.downvotes,
      score: Solution.score(solution),
      created_at: solution.inserted_at
    }
  end

  defp format_changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
    |> Enum.map(fn {field, errors} ->
      "#{field}: #{Enum.join(errors, ", ")}"
    end)
    |> Enum.join("; ")
  end
end
