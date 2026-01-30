defmodule Chorus.EmbeddingsTest do
  use ExUnit.Case, async: true

  alias Chorus.Embeddings

  # Sample embedding for integration tests (1536 dimensions)
  # @sample_embedding List.duplicate(0.1, 1536)

  describe "generate/1" do
    test "returns error for empty text" do
      assert {:error, :empty_text} = Embeddings.generate("")
    end

    test "returns error for nil text" do
      assert {:error, :empty_text} = Embeddings.generate(nil)
    end
  end

  describe "generate!/1" do
    test "raises on empty text" do
      assert_raise RuntimeError, ~r/Embedding generation failed/, fn ->
        Embeddings.generate!("")
      end
    end
  end

  describe "generate_async/1" do
    test "returns a Task" do
      # Note: This will fail without proper mocking since no API key
      # In a real test, we'd mock the API
      task = Embeddings.generate_async("test")
      assert %Task{} = task
      # Cancel the task since we don't want to wait for API timeout
      Task.shutdown(task, :brutal_kill)
    end
  end

  describe "model/0" do
    test "returns the OpenAI embedding model" do
      assert Embeddings.model() == "openai:text-embedding-3-small"
    end
  end

  describe "dimensions/0" do
    test "returns 1536 dimensions" do
      assert Embeddings.dimensions() == 1536
    end
  end

  describe "integration with req_llm (mocked)" do
    @describetag :integration

    setup do
      # Skip these tests if no API key is configured
      # In CI, we'd use fixtures or proper mocks
      :ok
    end

    # Note: These tests demonstrate the expected behavior.
    # In a real test suite, we'd use req_llm's fixture option
    # or Req.Test to mock the HTTP calls.
    #
    # Example with fixture (if available):
    #   Embeddings.generate("test", fixture: "embedding_response")
    #
    # Example with Req.Test:
    #   Req.Test.stub(ReqLLM, fn conn ->
    #     Req.Test.json(conn, %{
    #       "data" => [%{"embedding" => @sample_embedding}],
    #       "usage" => %{"prompt_tokens" => 5, "total_tokens" => 5}
    #     })
    #   end)

    @tag :skip
    test "generates embedding for text" do
      {:ok, embedding, latency_ms} = Embeddings.generate("How to implement binary search")
      assert is_list(embedding)
      assert length(embedding) == 1536
      assert is_integer(latency_ms)
      assert latency_ms > 0
    end
  end
end
