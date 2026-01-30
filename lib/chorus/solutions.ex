defmodule Chorus.Solutions do
  @moduledoc """
  The Solutions context handles creating, querying, and managing solutions.
  """

  import Ecto.Query
  alias Chorus.Repo
  alias Chorus.Solutions.Solution
  alias Chorus.Embeddings

  @doc """
  Creates a solution with automatic embedding generation.

  The embedding is generated synchronously for simplicity in the MVP.
  For production, consider using async embedding generation.

  ## Examples

      {:ok, solution} = create_solution(%{
        problem_description: "How to implement binary search",
        solution_pattern: "Use divide and conquer..."
      })

  """
  @spec create_solution(map()) :: {:ok, Solution.t()} | {:error, Ecto.Changeset.t()}
  def create_solution(attrs) do
    changeset = Solution.changeset(%Solution{}, attrs)

    if changeset.valid? do
      # Generate embedding from problem_description + solution_pattern
      text = build_embedding_text(attrs)

      case generate_embedding_for_solution(text, changeset) do
        {:ok, changeset_with_embedding} ->
          Repo.insert(changeset_with_embedding)

        {:error, reason} ->
          # Still create the solution without embedding if embedding fails
          # Log the error but don't fail the creation
          require Logger
          Logger.warning("Embedding generation failed: #{inspect(reason)}")
          Repo.insert(changeset)
      end
    else
      {:error, changeset}
    end
  end

  defp build_embedding_text(attrs) do
    problem = Map.get(attrs, :problem_description) || Map.get(attrs, "problem_description") || ""
    solution = Map.get(attrs, :solution_pattern) || Map.get(attrs, "solution_pattern") || ""
    "Problem: #{problem}\nSolution: #{solution}"
  end

  defp generate_embedding_for_solution(text, changeset) do
    case Embeddings.generate(text) do
      {:ok, embedding, _latency_ms} ->
        {:ok, Ecto.Changeset.put_change(changeset, :embedding, embedding)}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Gets a solution by ID.

  ## Examples

      {:ok, solution} = get_solution("uuid")
      {:error, :not_found} = get_solution("nonexistent")

  """
  @spec get_solution(binary()) :: {:ok, Solution.t()} | {:error, :not_found}
  def get_solution(id) do
    case Repo.get(Solution, id) do
      nil -> {:error, :not_found}
      solution -> {:ok, solution}
    end
  end

  @doc """
  Gets a solution by ID, raising if not found.
  """
  @spec get_solution!(binary()) :: Solution.t()
  def get_solution!(id) do
    Repo.get!(Solution, id)
  end

  @doc """
  Lists solutions with optional filters.

  ## Options

  - `:limit` - Maximum number of results (default: 20)
  - `:offset` - Number of results to skip (default: 0)
  - `:order_by` - Field to order by (:score, :inserted_at) (default: :score)

  """
  @spec list_solutions(keyword()) :: [Solution.t()]
  def list_solutions(opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)
    order_by = Keyword.get(opts, :order_by, :score)

    query =
      from s in Solution,
        limit: ^limit,
        offset: ^offset

    query =
      case order_by do
        :score ->
          from s in query, order_by: [desc: fragment("? - ?", s.upvotes, s.downvotes)]

        :inserted_at ->
          from s in query, order_by: [desc: s.inserted_at]

        _ ->
          query
      end

    Repo.all(query)
  end
end
