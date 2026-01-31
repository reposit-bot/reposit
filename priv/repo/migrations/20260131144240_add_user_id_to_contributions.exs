defmodule Reposit.Repo.Migrations.AddUserIdToContributions do
  use Ecto.Migration

  def change do
    # Add user_id to solutions table
    alter table(:solutions) do
      add :user_id, references(:users, on_delete: :delete_all)
    end

    create index(:solutions, [:user_id])

    # Add user_id to votes table
    alter table(:votes) do
      add :user_id, references(:users, on_delete: :delete_all)
    end

    create index(:votes, [:user_id])

    # Add unique constraint to enforce one vote per user per solution
    # This replaces the agent_session_id-based constraint for authenticated users
    create unique_index(:votes, [:solution_id, :user_id],
             where: "user_id IS NOT NULL",
             name: :votes_solution_id_user_id_unique
           )
  end
end
