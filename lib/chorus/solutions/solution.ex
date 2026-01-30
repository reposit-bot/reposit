defmodule Chorus.Solutions.Solution do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "solutions" do
    field :problem_description, :string
    field :solution_pattern, :string
    field :context_requirements, :map, default: %{}
    field :embedding, Pgvector.Ecto.Vector
    field :tags, :map, default: %{language: [], framework: [], domain: [], platform: []}
    field :upvotes, :integer, default: 0
    field :downvotes, :integer, default: 0

    has_many :votes, Chorus.Votes.Vote

    timestamps(type: :utc_datetime_usec)
  end

  @required_fields [:problem_description, :solution_pattern]
  @optional_fields [:context_requirements, :embedding, :tags]

  @doc """
  Changeset for creating a new solution.
  """
  def changeset(solution, attrs) do
    solution
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_length(:problem_description, min: 20)
    |> validate_length(:solution_pattern, min: 50)
    |> validate_tags()
  end

  @doc """
  Changeset for updating vote counts. Only allows upvotes/downvotes to be updated.
  """
  def vote_changeset(solution, attrs) do
    solution
    |> cast(attrs, [:upvotes, :downvotes])
    |> validate_number(:upvotes, greater_than_or_equal_to: 0)
    |> validate_number(:downvotes, greater_than_or_equal_to: 0)
  end

  defp validate_tags(changeset) do
    validate_change(changeset, :tags, fn :tags, tags ->
      valid_keys = ~w(language framework domain platform)a

      case tags do
        %{} = map ->
          invalid_keys = Map.keys(map) -- valid_keys

          if Enum.empty?(invalid_keys) do
            []
          else
            [tags: "contains invalid keys: #{inspect(invalid_keys)}"]
          end

        _ ->
          [tags: "must be a map"]
      end
    end)
  end

  @doc """
  Calculate the score (upvotes - downvotes) for a solution.
  """
  def score(%__MODULE__{upvotes: up, downvotes: down}), do: up - down
end
