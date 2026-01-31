defmodule Reposit.Solutions.Solution do
  use Reposit.Schema

  @statuses [:active, :archived]

  schema "solutions" do
    field(:problem_description, :string)
    field(:solution_pattern, :string)
    field(:context_requirements, :map, default: %{})
    field(:embedding, Pgvector.Ecto.Vector)
    field(:tags, :map, default: %{language: [], framework: [], domain: [], platform: []})
    field(:upvotes, :integer, default: 0)
    field(:downvotes, :integer, default: 0)
    field(:status, Ecto.Enum, values: @statuses, default: :active)

    has_many(:votes, Reposit.Votes.Vote)

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Returns the list of valid statuses.
  """
  def statuses, do: @statuses

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
      valid_keys = MapSet.new(~w(language framework domain platform))

      case tags do
        %{} = map ->
          # Normalize all keys to strings for comparison
          keys = map |> Map.keys() |> Enum.map(&to_string/1) |> MapSet.new()
          invalid_keys = MapSet.difference(keys, valid_keys)

          if MapSet.size(invalid_keys) == 0 do
            []
          else
            [tags: "contains invalid keys: #{inspect(MapSet.to_list(invalid_keys))}"]
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
