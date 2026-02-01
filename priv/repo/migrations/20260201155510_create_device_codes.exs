defmodule Reposit.Repo.Migrations.CreateDeviceCodes do
  use Ecto.Migration

  def change do
    create table(:device_codes) do
      add :device_code, :binary, null: false
      add :user_code, :string, null: false
      add :user_id, references(:users, on_delete: :delete_all)
      add :backend_url, :string, null: false
      add :expires_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index(:device_codes, [:device_code])
    create unique_index(:device_codes, [:user_code])
    create index(:device_codes, [:expires_at])
  end
end
