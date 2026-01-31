defmodule Reposit.Repo.Migrations.DropAgentSessionIdFromVotes do
  use Ecto.Migration

  def change do
    # Drop the old unique index based on agent_session_id
    drop_if_exists index(:votes, [:solution_id, :agent_session_id])

    # Remove the agent_session_id column
    alter table(:votes) do
      remove :agent_session_id, :string
    end
  end
end
