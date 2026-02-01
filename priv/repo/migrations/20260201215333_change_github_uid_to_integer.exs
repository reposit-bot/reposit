defmodule Reposit.Repo.Migrations.ChangeGithubUidToInteger do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE users ALTER COLUMN github_uid TYPE bigint USING github_uid::bigint"
  end

  def down do
    execute "ALTER TABLE users ALTER COLUMN github_uid TYPE varchar USING github_uid::varchar"
  end
end
