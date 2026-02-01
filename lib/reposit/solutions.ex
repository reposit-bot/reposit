defmodule Reposit.Solutions do
  @moduledoc """
  The Solutions context handles creating, querying, and managing solutions.
  """

  import Ecto.Query
  alias Reposit.Repo
  alias Reposit.Solutions.Solution
  alias Reposit.Embeddings
  alias Reposit.ContentSafety
  alias Reposit.Accounts.Scope

  @doc """
  Creates a solution with automatic embedding generation.

  The embedding is generated synchronously for simplicity in the MVP.
  For production, consider using async embedding generation.

  ## Examples

      {:ok, solution} = create_solution(scope, %{
        problem_description: "How to implement binary search",
        solution_pattern: "Use divide and conquer..."
      })

  """
  @spec create_solution(Scope.t(), map()) ::
          {:ok, Solution.t()} | {:error, Ecto.Changeset.t() | :content_unsafe}
  def create_solution(%Scope{user: %{id: user_id}}, attrs) do
    # Add user_id with the same key type as the attrs map
    attrs = put_with_matching_key_type(attrs, :user_id, user_id)

    # Check content safety before processing
    case check_content_safety(attrs) do
      :ok ->
        create_solution_unsafe(attrs)

      {:error, :content_unsafe} = error ->
        error
    end
  end

  # Puts a key-value pair using the same key type (atom or string) as the existing map
  defp put_with_matching_key_type(map, key, value) when is_atom(key) do
    if has_string_keys?(map) do
      Map.put(map, Atom.to_string(key), value)
    else
      Map.put(map, key, value)
    end
  end

  defp has_string_keys?(map) do
    map |> Map.keys() |> Enum.any?(&is_binary/1)
  end

  defp create_solution_unsafe(attrs) do
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

  defp check_content_safety(attrs) do
    problem = Map.get(attrs, :problem_description) || Map.get(attrs, "problem_description") || ""
    solution = Map.get(attrs, :solution_pattern) || Map.get(attrs, "solution_pattern") || ""

    # context_requirements is a map, so we need to convert it to a string for safety check
    context = Map.get(attrs, :context_requirements) || Map.get(attrs, "context_requirements")

    context_str =
      case context do
        nil -> ""
        ctx when is_map(ctx) -> Jason.encode!(ctx)
        ctx when is_binary(ctx) -> ctx
        _ -> ""
      end

    content = "#{problem}\n#{solution}\n#{context_str}"

    if ContentSafety.risky?(content) do
      require Logger
      Logger.warning("Content safety check failed for solution submission")
      {:error, :content_unsafe}
    else
      :ok
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
  Gets a solution by ID with preloaded votes.

  Votes are ordered by most recent first and limited for display.
  """
  @spec get_solution_with_votes(binary(), keyword()) :: {:ok, Solution.t()} | {:error, :not_found}
  def get_solution_with_votes(id, opts \\ []) do
    limit = Keyword.get(opts, :votes_limit, 10)

    votes_query =
      from(v in Reposit.Votes.Vote,
        order_by: [desc: v.inserted_at],
        limit: ^limit
      )

    query =
      from(s in Solution,
        where: s.id == ^id,
        preload: [:user, votes: ^votes_query]
      )

    case Repo.one(query) do
      nil -> {:error, :not_found}
      solution -> {:ok, Repo.preload(solution, votes: [:user])}
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
  Counts total solutions.
  """
  @spec count_solutions() :: non_neg_integer()
  def count_solutions do
    Repo.aggregate(Solution, :count)
  end

  @doc """
  Counts solutions for a user.
  """
  @spec count_solutions_by_user(integer()) :: non_neg_integer()
  def count_solutions_by_user(user_id) do
    from(s in Solution, where: s.user_id == ^user_id)
    |> Repo.aggregate(:count)
  end

  @doc """
  Lists solutions by user ID for public profile.

  ## Options

  - `:limit` - Maximum number of results (default: 20)
  - `:offset` - Number of results to skip (default: 0)
  - `:order_by` - Field to order by (:score, :inserted_at, :upvotes) (default: :inserted_at)

  """
  @spec list_solutions_by_user(integer(), keyword()) :: [Solution.t()]
  def list_solutions_by_user(user_id, opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)
    order_by = Keyword.get(opts, :order_by, :inserted_at)

    query =
      from(s in Solution,
        where: s.user_id == ^user_id and s.status == :active,
        limit: ^limit,
        offset: ^offset
      )

    query =
      case order_by do
        :score ->
          from(s in query, order_by: [desc: fragment("? - ?", s.upvotes, s.downvotes)])

        :inserted_at ->
          from(s in query, order_by: [desc: s.inserted_at])

        :upvotes ->
          from(s in query, order_by: [desc: s.upvotes])

        _ ->
          from(s in query, order_by: [desc: s.inserted_at])
      end

    query
    |> Repo.all()
  end

  @doc """
  Lists solutions with optional filters.

  ## Options

  - `:limit` - Maximum number of results (default: 20)
  - `:offset` - Number of results to skip (default: 0)
  - `:order_by` - Field to order by (:score, :inserted_at, :upvotes) (default: :score)

  """
  @spec list_solutions(keyword()) :: [Solution.t()]
  def list_solutions(opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    offset = Keyword.get(opts, :offset, 0)
    order_by = Keyword.get(opts, :order_by, :score)

    query =
      from(s in Solution,
        limit: ^limit,
        offset: ^offset
      )

    query =
      case order_by do
        :score ->
          from(s in query, order_by: [desc: fragment("? - ?", s.upvotes, s.downvotes)])

        :inserted_at ->
          from(s in query, order_by: [desc: s.inserted_at])

        :upvotes ->
          from(s in query, order_by: [desc: s.upvotes])

        _ ->
          query
      end

    query
    |> preload(:user)
    |> Repo.all()
  end

  @doc """
  Searches solutions using semantic similarity.

  Generates an embedding for the query and finds similar solutions using
  pgvector's cosine distance operator.

  ## Options

  - `:limit` - Maximum number of results (default: 10, max: 50)
  - `:required_tags` - Map of tags that must match (e.g., %{language: ["elixir"]})
  - `:exclude_tags` - Map of tags to exclude
  - `:sort` - Sort order: :relevance (default), :newest, :top_voted

  ## Returns

  `{:ok, results, total}` where results include a `similarity` score (0.0 to 1.0).

  ## Examples

      {:ok, results, total} = search_solutions("How to implement GenServer", limit: 5)

  """
  @spec search_solutions(String.t(), keyword()) ::
          {:ok, [map()], non_neg_integer()} | {:error, term()}
  def search_solutions(query, opts \\ [])

  def search_solutions("", _opts), do: {:error, :empty_query}
  def search_solutions(nil, _opts), do: {:error, :empty_query}

  def search_solutions(query, opts) when is_binary(query) and byte_size(query) > 0 do
    limit = opts |> Keyword.get(:limit, 10) |> min(50)
    required_tags = Keyword.get(opts, :required_tags, %{})
    exclude_tags = Keyword.get(opts, :exclude_tags, %{})
    sort = Keyword.get(opts, :sort, :relevance)

    case Embeddings.generate(query) do
      {:ok, query_embedding, _latency} ->
        {results, total} =
          execute_search(query_embedding, limit, required_tags, exclude_tags, sort)

        {:ok, results, total}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp execute_search(query_embedding, limit, required_tags, exclude_tags, sort) do
    # Base query - we'll add similarity in select
    base_query =
      from(s in Solution,
        where: not is_nil(s.embedding)
      )

    # Apply tag filters
    query = apply_tag_filters(base_query, required_tags, exclude_tags)

    # Get total count (without limit, before adding similarity select)
    total = Repo.aggregate(query, :count)

    # Add similarity calculation and sorting
    query =
      from(s in query,
        select: %{
          id: s.id,
          problem_description: s.problem_description,
          solution_pattern: s.solution_pattern,
          tags: s.tags,
          upvotes: s.upvotes,
          downvotes: s.downvotes,
          inserted_at: s.inserted_at,
          similarity: fragment("1 - (? <=> ?)", s.embedding, ^query_embedding)
        }
      )

    # Apply sorting using fragment for similarity
    query = apply_sort(query, sort, query_embedding)

    # Apply limit and fetch results
    results =
      query
      |> limit(^limit)
      |> Repo.all()
      |> Enum.map(fn row ->
        # Handle NaN from stub embeddings (all zeros)
        similarity =
          case row.similarity do
            val when is_float(val) and val == val -> Float.round(val, 4)
            _ -> 0.0
          end

        %{row | similarity: similarity}
      end)

    {results, total}
  end

  defp apply_tag_filters(query, required_tags, exclude_tags) do
    query
    |> apply_required_tags(required_tags)
    |> apply_exclude_tags(exclude_tags)
  end

  defp apply_required_tags(query, tags) when map_size(tags) == 0, do: query

  defp apply_required_tags(query, tags) do
    Enum.reduce(tags, query, fn {category, values}, acc ->
      category_str = to_string(category)

      Enum.reduce(values, acc, fn value, q ->
        # Check if the JSONB array at category contains the value
        # Use to_jsonb() with text[] for proper type handling
        from(s in q,
          where:
            fragment(
              "COALESCE(? -> ? @> to_jsonb(?::text[]), false)",
              s.tags,
              ^category_str,
              ^[value]
            )
        )
      end)
    end)
  end

  defp apply_exclude_tags(query, tags) when map_size(tags) == 0, do: query

  defp apply_exclude_tags(query, tags) do
    Enum.reduce(tags, query, fn {category, values}, acc ->
      category_str = to_string(category)

      Enum.reduce(values, acc, fn value, q ->
        # Exclude if the JSONB array at category contains the value
        from(s in q,
          where:
            not fragment(
              "COALESCE(? -> ? @> to_jsonb(?::text[]), false)",
              s.tags,
              ^category_str,
              ^[value]
            )
        )
      end)
    end)
  end

  defp apply_sort(query, :relevance, query_embedding) do
    # Order by cosine similarity (1 - distance), higher is more similar
    from(s in query, order_by: [asc: fragment("? <=> ?", s.embedding, ^query_embedding)])
  end

  defp apply_sort(query, :newest, _query_embedding) do
    from(s in query, order_by: [desc: s.inserted_at])
  end

  defp apply_sort(query, :top_voted, _query_embedding) do
    from(s in query, order_by: [desc: fragment("? - ?", s.upvotes, s.downvotes)])
  end

  defp apply_sort(query, _, query_embedding), do: apply_sort(query, :relevance, query_embedding)

  # Moderation functions

  @doc """
  Lists flagged solutions that need moderation review.

  A solution is flagged if:
  - downvotes > upvotes, OR
  - downvotes >= 3

  Preloads votes with comments for moderator review.

  ## Options
  - `:reason` - Filter by downvote reason
  - `:limit` - Maximum results (default: 20)
  """
  @spec list_flagged_solutions(keyword()) :: [Solution.t()]
  def list_flagged_solutions(opts \\ []) do
    limit = Keyword.get(opts, :limit, 20)
    reason = Keyword.get(opts, :reason)

    # Only show active solutions that need moderation
    query =
      from(s in Solution,
        where: s.status == :active,
        where: s.downvotes > s.upvotes or s.downvotes >= 3,
        order_by: [desc: s.downvotes],
        limit: ^limit
      )

    # Optionally filter by reason
    query =
      if reason do
        votes_with_reason =
          from(v in Reposit.Votes.Vote,
            where: v.vote_type == :down and v.reason == ^reason,
            select: v.solution_id
          )

        from(s in query,
          where: s.id in subquery(votes_with_reason)
        )
      else
        query
      end

    # Preload downvotes with comments
    votes_query =
      from(v in Reposit.Votes.Vote,
        where: v.vote_type == :down,
        order_by: [desc: v.inserted_at]
      )

    query
    |> preload(votes: ^votes_query)
    |> Repo.all()
  end

  @doc """
  Archives a solution (soft delete).
  """
  @spec archive_solution(binary()) ::
          {:ok, Solution.t()} | {:error, :not_found | Ecto.Changeset.t()}
  def archive_solution(id) do
    case Repo.get(Solution, id) do
      nil ->
        {:error, :not_found}

      solution ->
        solution
        |> Ecto.Changeset.change(status: :archived)
        |> Repo.update()
    end
  end

  @doc """
  Approves a solution (keeps it active, clears flags by confirming quality).
  For MVP, this just confirms the solution stays active.
  """
  @spec approve_solution(binary()) :: {:ok, Solution.t()} | {:error, :not_found}
  def approve_solution(id) do
    case Repo.get(Solution, id) do
      nil -> {:error, :not_found}
      solution -> {:ok, solution}
    end
  end

  @doc """
  Deletes a solution if the user is the owner.

  This is a hard delete that also removes all associated votes.

  ## Examples

      {:ok, solution} = delete_solution(scope, solution_id)
      {:error, :not_found} = delete_solution(scope, nonexistent_id)
      {:error, :unauthorized} = delete_solution(scope, other_users_solution_id)

  """
  @spec delete_solution(Scope.t(), binary()) ::
          {:ok, Solution.t()} | {:error, :not_found | :unauthorized}
  def delete_solution(%Scope{user: %{id: user_id}}, solution_id) do
    case Repo.get(Solution, solution_id) do
      nil ->
        {:error, :not_found}

      %Solution{user_id: ^user_id} = solution ->
        # User owns this solution - delete it (votes cascade due to FK)
        Repo.delete(solution)

      _solution ->
        {:error, :unauthorized}
    end
  end
end
