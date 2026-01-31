defmodule Reposit.Repo.Migrations.AddOauthToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :google_uid, :string
      add :github_uid, :string
      add :name, :string
      add :avatar_url, :string
    end

    create unique_index(:users, [:google_uid])
    create unique_index(:users, [:github_uid])
  end
end
