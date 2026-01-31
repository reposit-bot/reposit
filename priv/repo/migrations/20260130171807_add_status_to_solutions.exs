defmodule Reposit.Repo.Migrations.AddStatusToSolutions do
  use Ecto.Migration

  def change do
    alter table(:solutions) do
      add(:status, :string, default: "active", null: false)
    end

    create(index(:solutions, [:status]))
  end
end
