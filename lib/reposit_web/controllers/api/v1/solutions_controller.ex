defmodule RepositWeb.Api.V1.SolutionsController do
  use RepositWeb, :controller

  alias Reposit.Solutions
  alias Reposit.Solutions.Solution

  action_fallback(RepositWeb.Api.V1.FallbackController)

  @doc """
  Creates a new solution.

  POST /api/v1/solutions
  """
  def create(conn, params) do
    scope = conn.assigns.current_scope

    case Solutions.create_solution(scope, params) do
      {:ok, solution} ->
        conn
        |> put_status(:created)
        |> json(%{
          success: true,
          data: solution_json(solution)
        })

      {:error, :content_unsafe} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          success: false,
          error: "content_unsafe",
          hint: "Content contains potentially unsafe patterns. Please revise and try again."
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
  Searches solutions using semantic similarity.

  GET /api/v1/solutions/search?q=query
  """
  def search(conn, params) do
    query = Map.get(params, "q", "")
    limit = parse_limit(params)
    sort = parse_sort(params)
    required_tags = merge_required_tags(params)
    exclude_tags = parse_tags(params, "exclude_tags")

    if query == "" do
      conn
      |> put_status(:bad_request)
      |> json(%{
        success: false,
        error: "missing_query",
        hint: "Query parameter 'q' is required"
      })
    else
      case Solutions.search_solutions(query,
             limit: limit,
             sort: sort,
             required_tags: required_tags,
             exclude_tags: exclude_tags
           ) do
        {:ok, results, total} ->
          json(conn, %{
            success: true,
            data: %{
              solutions: Enum.map(results, &search_result_json/1),
              total: total
            }
          })

        {:error, reason} ->
          conn
          |> put_status(:internal_server_error)
          |> json(%{
            success: false,
            error: "search_failed",
            hint: "Search failed: #{inspect(reason)}"
          })
      end
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
      problem: solution.problem,
      solution: solution.solution,
      tags: solution.tags,
      upvotes: solution.upvotes,
      downvotes: solution.downvotes,
      score: Solution.score(solution),
      created_at: solution.inserted_at,
      url: url(~p"/solutions/#{solution.id}")
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

  defp search_result_json(result) do
    %{
      id: result.id,
      problem: result.problem,
      solution: result.solution,
      tags: result.tags,
      similarity: result.similarity,
      upvotes: result.upvotes,
      downvotes: result.downvotes,
      score: result.upvotes - result.downvotes
    }
  end

  defp parse_limit(params) do
    case Map.get(params, "limit") do
      nil -> 10
      val when is_binary(val) -> String.to_integer(val) |> min(50) |> max(1)
      val when is_integer(val) -> min(val, 50) |> max(1)
    end
  rescue
    _ -> 10
  end

  defp parse_sort(params) do
    case Map.get(params, "sort") do
      "newest" -> :newest
      "top_voted" -> :top_voted
      _ -> :relevance
    end
  end

  defp parse_tags(params, key) do
    case Map.get(params, key) do
      nil ->
        %{}

      tags when is_binary(tags) ->
        # Parse comma-separated format: "language:elixir,framework:phoenix"
        tags
        |> String.split(",", trim: true)
        |> Enum.reduce(%{}, fn tag, acc ->
          case String.split(tag, ":", parts: 2) do
            [category, value] ->
              category = String.trim(category)
              value = String.trim(value)
              Map.update(acc, category, [value], &[value | &1])

            _ ->
              acc
          end
        end)

      tags when is_map(tags) ->
        tags
    end
  end

  # Merges flat tags (from ?tags=elixir,phoenix) with structured tags (from ?required_tags=language:elixir)
  # Flat tags use the special :_any key to match against any category
  defp merge_required_tags(params) do
    structured = parse_tags(params, "required_tags")
    flat = parse_flat_tags(params)

    if flat == [] do
      structured
    else
      Map.put(structured, :_any, flat)
    end
  end

  defp parse_flat_tags(params) do
    case Map.get(params, "tags") do
      nil ->
        []

      tags when is_binary(tags) ->
        tags |> String.split(",", trim: true) |> Enum.map(&String.trim/1)

      tags when is_list(tags) ->
        Enum.map(tags, &to_string/1)

      _ ->
        []
    end
  end
end
