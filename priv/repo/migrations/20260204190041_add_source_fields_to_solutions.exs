defmodule Reposit.Repo.Migrations.AddSourceFieldsToSolutions do
  use Ecto.Migration

  def change do
    alter table(:solutions) do
      add :source_url, :string
      add :source_author, :string
      add :source_author_url, :string
    end

    create index(:solutions, [:source_author])
  end
end
