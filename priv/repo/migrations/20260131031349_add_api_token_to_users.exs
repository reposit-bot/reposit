defmodule Reposit.Repo.Migrations.AddApiTokenToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:api_token_hash, :binary)
    end

    create(unique_index(:users, [:api_token_hash]))
  end
end
