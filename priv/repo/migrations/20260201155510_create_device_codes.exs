defmodule Reposit.Repo.Migrations.CreateDeviceCodes do
  use Ecto.Migration

  def change do
    create table(:device_codes, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:device_code, :binary, null: false)
      add(:user_code, :string, null: false)
      add(:user_id, references(:users, type: :binary_id, on_delete: :delete_all))
      add(:backend_url, :string, null: false)
      add(:expires_at, :utc_datetime, null: false)

      timestamps(type: :utc_datetime_usec, updated_at: false)
    end

    create(unique_index(:device_codes, [:device_code]))
    create(unique_index(:device_codes, [:user_code]))
    create(index(:device_codes, [:expires_at]))
  end
end
