defmodule Reposit.Repo.Migrations.RemoveApiTokenHashFromUsers do
  use Ecto.Migration

  def change do
    drop_if_exists index(:users, [:api_token_hash])

    alter table(:users) do
      remove :api_token_hash, :binary
    end
  end
end
