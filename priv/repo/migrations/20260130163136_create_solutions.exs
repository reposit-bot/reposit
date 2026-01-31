defmodule Reposit.Repo.Migrations.CreateSolutions do
  use Ecto.Migration

  def change do
    create table(:solutions, primary_key: false) do
      add(:id, :binary_id, primary_key: true)
      add(:problem_description, :text, null: false)
      add(:solution_pattern, :text, null: false)
      add(:context_requirements, :map, default: %{})
      add(:embedding, :vector, size: 1536)
      add(:tags, :map, default: %{language: [], framework: [], domain: [], platform: []})
      add(:upvotes, :integer, default: 0, null: false)
      add(:downvotes, :integer, default: 0, null: false)

      timestamps(type: :utc_datetime_usec)
    end

    # Index for sorting by score (upvotes - downvotes)
    create(index(:solutions, ["(upvotes - downvotes) DESC"], name: :solutions_score_index))

    # Index for temporal queries
    create(index(:solutions, [:inserted_at]))

    # HNSW index for fast vector similarity search
    # Using cosine distance operator (<=>)
    execute(
      "CREATE INDEX solutions_embedding_index ON solutions USING hnsw (embedding vector_cosine_ops)",
      "DROP INDEX IF EXISTS solutions_embedding_index"
    )
  end
end
