defmodule Reposit.Embeddings do
  @moduledoc """
  Handles embedding generation using OpenAI's text-embedding-3-small model.

  Uses req_llm for the OpenAI API integration.

  ## Test Mode

  In test environment, returns a stub embedding by default to avoid API calls.
  Set `config :reposit, :embeddings_stub, false` to enable real API calls for
  integration tests.
  """

  require Logger

  @model "openai:text-embedding-3-small"
  @dimensions 1536

  @doc """
  Generates an embedding vector for the given text.

  Returns `{:ok, embedding, latency_ms}` on success, where:
  - `embedding` is a list of 1536 floats
  - `latency_ms` is the API call duration in milliseconds

  Returns `{:error, reason}` on failure.

  ## Examples

      {:ok, embedding, latency_ms} = Reposit.Embeddings.generate("How to implement binary search in Elixir")
      # embedding is a list of 1536 floats
      # latency_ms is ~50-200ms typically

  """
  @spec generate(String.t()) :: {:ok, [float()], non_neg_integer()} | {:error, term()}
  def generate(text) when is_binary(text) and byte_size(text) > 0 do
    if stub_enabled?() do
      generate_stub(text)
    else
      generate_live(text)
    end
  end

  def generate(""), do: {:error, :empty_text}
  def generate(nil), do: {:error, :empty_text}

  defp stub_enabled? do
    Application.get_env(:reposit, :embeddings_stub, false)
  end

  defp generate_stub(_text) do
    # Return a deterministic fake embedding for testing
    embedding = List.duplicate(0.0, @dimensions)
    {:ok, embedding, 0}
  end

  defp generate_live(text) do
    start_time = System.monotonic_time(:millisecond)

    try do
      result = ReqLLM.Embedding.embed(@model, text, dimensions: @dimensions)

      latency_ms = System.monotonic_time(:millisecond) - start_time

      case result do
        {:ok, embedding} when is_list(embedding) ->
          Logger.debug("Generated embedding in #{latency_ms}ms (#{length(embedding)} dimensions)")
          {:ok, embedding, latency_ms}

        {:error, error} ->
          Logger.error("Embedding generation failed: #{inspect(error)}")
          {:error, error}
      end
    rescue
      e in [ReqLLM.Error.Invalid.Parameter] ->
        # Handle missing API key gracefully
        Logger.warning("Embedding generation skipped: #{Exception.message(e)}")
        {:error, :api_key_not_configured}
    end
  end

  @doc """
  Generates an embedding and returns only the vector, raising on error.

  ## Examples

      embedding = Reposit.Embeddings.generate!("How to implement binary search")
      # Returns list of 1536 floats, or raises on error

  """
  @spec generate!(String.t()) :: [float()]
  def generate!(text) do
    case generate(text) do
      {:ok, embedding, _latency} -> embedding
      {:error, error} -> raise "Embedding generation failed: #{inspect(error)}"
    end
  end

  @doc """
  Generates embeddings asynchronously using a Task.

  Returns a Task that can be awaited to get the result.

  ## Examples

      task = Reposit.Embeddings.generate_async("Some text to embed")
      # ... do other work ...
      {:ok, embedding, latency_ms} = Task.await(task)

  """
  @spec generate_async(String.t()) :: Task.t()
  def generate_async(text) do
    Task.async(fn -> generate(text) end)
  end

  @doc """
  Returns the model being used for embeddings.
  """
  @spec model() :: String.t()
  def model, do: @model

  @doc """
  Returns the number of dimensions in the embedding vectors.
  """
  @spec dimensions() :: pos_integer()
  def dimensions, do: @dimensions
end
