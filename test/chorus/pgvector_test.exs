defmodule Chorus.PgvectorTest do
  use Chorus.DataCase, async: true

  @moduletag :pgvector

  describe "pgvector extension" do
    test "vector type is available" do
      # Create a temporary table with a vector column
      Ecto.Adapters.SQL.query!(Chorus.Repo, """
      CREATE TEMPORARY TABLE test_vectors (
        id SERIAL PRIMARY KEY,
        embedding vector(3)
      )
      """)

      # Insert a vector
      Ecto.Adapters.SQL.query!(
        Chorus.Repo,
        "INSERT INTO test_vectors (embedding) VALUES ($1)",
        [Pgvector.new([1.0, 2.0, 3.0])]
      )

      # Query it back
      result =
        Ecto.Adapters.SQL.query!(
          Chorus.Repo,
          "SELECT embedding FROM test_vectors LIMIT 1"
        )

      assert [[vector]] = result.rows
      assert %Pgvector{} = vector
      assert Pgvector.to_list(vector) == [1.0, 2.0, 3.0]
    end

    test "cosine similarity search works" do
      Ecto.Adapters.SQL.query!(Chorus.Repo, """
      CREATE TEMPORARY TABLE test_vectors (
        id SERIAL PRIMARY KEY,
        embedding vector(3)
      )
      """)

      # Insert multiple vectors
      vectors = [
        [1.0, 0.0, 0.0],
        [0.0, 1.0, 0.0],
        [0.707, 0.707, 0.0]
      ]

      for v <- vectors do
        Ecto.Adapters.SQL.query!(
          Chorus.Repo,
          "INSERT INTO test_vectors (embedding) VALUES ($1)",
          [Pgvector.new(v)]
        )
      end

      # Query for vectors most similar to [1, 0, 0] using cosine distance
      query_vector = Pgvector.new([1.0, 0.0, 0.0])

      result =
        Ecto.Adapters.SQL.query!(
          Chorus.Repo,
          """
          SELECT id, embedding <=> $1 as distance
          FROM test_vectors
          ORDER BY distance
          LIMIT 2
          """,
          [query_vector]
        )

      [[id1, dist1], [id2, _dist2]] = result.rows
      assert id1 == 1
      assert dist1 == +0.0
      assert id2 == 3
    end
  end
end
