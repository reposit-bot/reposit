defmodule Chorus.Votes do
  @moduledoc """
  The Votes context handles voting on solutions.
  """

  import Ecto.Query
  alias Chorus.Repo
  alias Chorus.Votes.Vote
  alias Chorus.Solutions.Solution

  @doc """
  Creates a vote on a solution.

  Automatically updates the solution's vote count atomically.

  ## Examples

      {:ok, vote} = create_vote(%{
        solution_id: "uuid",
        agent_session_id: "agent-123",
        vote_type: :up
      })

  """
  @spec create_vote(map()) :: {:ok, Vote.t()} | {:error, Ecto.Changeset.t() | :solution_not_found}
  def create_vote(attrs) do
    solution_id = Map.get(attrs, :solution_id) || Map.get(attrs, "solution_id")

    # Verify solution exists
    case Repo.get(Solution, solution_id) do
      nil ->
        {:error, :solution_not_found}

      _solution ->
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
  end

  @doc """
  Gets a vote by solution and agent session ID.
  """
  @spec get_vote(binary(), binary()) :: Vote.t() | nil
  def get_vote(solution_id, agent_session_id) do
    Repo.get_by(Vote, solution_id: solution_id, agent_session_id: agent_session_id)
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
end
