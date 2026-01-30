defmodule Chorus.Repo.Migrations.CreateVotes do
  use Ecto.Migration

  def change do
    # Create enums
    execute(
      "CREATE TYPE vote_type AS ENUM ('up', 'down')",
      "DROP TYPE IF EXISTS vote_type"
    )

    execute(
      "CREATE TYPE downvote_reason AS ENUM ('incorrect', 'outdated', 'incomplete', 'harmful', 'duplicate', 'other')",
      "DROP TYPE IF EXISTS downvote_reason"
    )

    create table(:votes, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :solution_id, references(:solutions, type: :binary_id, on_delete: :delete_all),
        null: false

      add :agent_session_id, :string, null: false
      add :vote_type, :vote_type, null: false
      add :comment, :text
      add :reason, :downvote_reason

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    # Index for querying votes by solution
    create index(:votes, [:solution_id])

    # Unique constraint: one vote per agent per solution
    create unique_index(:votes, [:solution_id, :agent_session_id])
  end
end
