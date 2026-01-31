defmodule Reposit.Votes do
  @moduledoc """
  The Votes context handles voting on solutions.
  """

  import Ecto.Query
  alias Reposit.Repo
  alias Reposit.Votes.Vote
  alias Reposit.Solutions.Solution
  alias Reposit.ContentSafety

  @doc """
  Creates a vote on a solution.

  Automatically updates the solution's vote count atomically.

  ## Examples

      {:ok, vote} = create_vote(%{
        solution_id: "uuid",
        user_id: 123,
        vote_type: :up
      })

  """
  @spec create_vote(map()) ::
          {:ok, Vote.t()} | {:error, Ecto.Changeset.t() | :solution_not_found | :content_unsafe}
  def create_vote(attrs) do
    # Check content safety on comment if present
    case check_comment_safety(attrs) do
      :ok ->
        create_vote_unsafe(attrs)

      {:error, :content_unsafe} = error ->
        error
    end
  end

  defp create_vote_unsafe(attrs) do
    solution_id = Map.get(attrs, :solution_id) || Map.get(attrs, "solution_id")
    user_id = Map.get(attrs, :user_id) || Map.get(attrs, "user_id")

    # Verify solution exists
    case Repo.get(Solution, solution_id) do
      nil ->
        {:error, :solution_not_found}

      _solution ->
        # Check for existing vote by this user
        case get_vote(solution_id, user_id) do
          nil ->
            # No existing vote - create new one
            create_new_vote(attrs)

          existing_vote ->
            # Update existing vote (upsert)
            update_existing_vote(existing_vote, attrs)
        end
    end
  end

  defp create_new_vote(attrs) do
    Repo.transaction(fn ->
      changeset = Vote.changeset(%Vote{}, attrs)

      case Repo.insert(changeset) do
        {:ok, vote} ->
          # Update solution vote counts atomically
          update_solution_vote_count(vote.solution_id, vote.vote_type, :add)
          vote

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  defp update_existing_vote(existing_vote, attrs) do
    new_vote_type = Map.get(attrs, :vote_type) || Map.get(attrs, "vote_type")

    Repo.transaction(fn ->
      changeset = Vote.changeset(existing_vote, attrs)

      case Repo.update(changeset) do
        {:ok, vote} ->
          # Adjust vote counts if vote type changed
          if existing_vote.vote_type != new_vote_type do
            update_solution_vote_count(vote.solution_id, existing_vote.vote_type, :remove)
            update_solution_vote_count(vote.solution_id, new_vote_type, :add)
          end

          vote

        {:error, changeset} ->
          Repo.rollback(changeset)
      end
    end)
  end

  defp check_comment_safety(attrs) do
    comment = Map.get(attrs, :comment) || Map.get(attrs, "comment")

    if comment && ContentSafety.risky?(comment) do
      require Logger
      Logger.warning("Content safety check failed for vote comment")
      {:error, :content_unsafe}
    else
      :ok
    end
  end

  @doc """
  Gets a vote by solution and user ID.
  """
  @spec get_vote(binary(), integer()) :: Vote.t() | nil
  def get_vote(solution_id, user_id) do
    Repo.get_by(Vote, solution_id: solution_id, user_id: user_id)
  end

  # Updates the solution vote counts atomically.
  defp update_solution_vote_count(solution_id, vote_type, operation) do
    {field, change} =
      case {vote_type, operation} do
        {:up, :add} -> {:upvotes, 1}
        {:up, :remove} -> {:upvotes, -1}
        {:down, :add} -> {:downvotes, 1}
        {:down, :remove} -> {:downvotes, -1}
      end

    from(s in Solution, where: s.id == ^solution_id)
    |> Repo.update_all(inc: [{field, change}])
  end

  @doc """
  Returns vote types.
  """
  def vote_types, do: Vote.vote_types()

  @doc """
  Returns downvote reasons.
  """
  def downvote_reasons, do: Vote.downvote_reasons()

  @doc """
  Counts total votes.
  """
  @spec count_votes() :: non_neg_integer()
  def count_votes do
    Repo.aggregate(Vote, :count)
  end
end
