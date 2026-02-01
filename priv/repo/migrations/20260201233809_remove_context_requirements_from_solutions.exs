defmodule Reposit.Repo.Migrations.RemoveContextRequirementsFromSolutions do
  use Ecto.Migration

  def change do
    alter table(:solutions) do
      remove :context_requirements
    end
  end
end
