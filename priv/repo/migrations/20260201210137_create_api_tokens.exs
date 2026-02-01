defmodule Reposit.Repo.Migrations.CreateApiTokens do
  use Ecto.Migration

  def change do
    create table(:api_tokens, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:token_hash, :binary, null: false)
      add(:name, :string, null: false)
      add(:source, :string, null: false)
      add(:device_name, :string)
      add(:last_used_at, :utc_datetime)
      add(:user_id, references(:users, type: :binary_id, on_delete: :delete_all), null: false)

      timestamps(type: :utc_datetime_usec)
    end

    create(unique_index(:api_tokens, [:token_hash]))
    create(index(:api_tokens, [:user_id]))
    create(index(:api_tokens, [:user_id, :inserted_at]))
  end
end
