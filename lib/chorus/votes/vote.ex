defmodule Chorus.Votes.Vote do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @vote_types [:up, :down]
  @downvote_reasons [:incorrect, :outdated, :incomplete, :harmful, :duplicate, :other]

  schema "votes" do
    field :agent_session_id, :string
    field :vote_type, Ecto.Enum, values: @vote_types
    field :comment, :string
    field :reason, Ecto.Enum, values: @downvote_reasons

    belongs_to :solution, Chorus.Solutions.Solution

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  @required_fields [:solution_id, :agent_session_id, :vote_type]
  @optional_fields [:comment, :reason]

  @doc """
  Changeset for creating a vote.

  Downvotes require a comment and reason. Upvotes cannot have comments or reasons.
  """
  def changeset(vote, attrs) do
    vote
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:vote_type, @vote_types)
    |> validate_downvote_requirements()
    |> validate_upvote_has_no_comment()
    |> foreign_key_constraint(:solution_id)
    |> unique_constraint([:solution_id, :agent_session_id],
      name: :votes_solution_id_agent_session_id_index,
      message: "already voted on this solution"
    )
  end

  defp validate_downvote_requirements(changeset) do
    case get_field(changeset, :vote_type) do
      :down ->
        changeset
        |> validate_required([:comment, :reason], message: "is required for downvotes")
        |> validate_length(:comment, min: 10, message: "must be at least 10 characters")

      _ ->
        changeset
    end
  end

  defp validate_upvote_has_no_comment(changeset) do
    case get_field(changeset, :vote_type) do
      :up ->
        comment = get_field(changeset, :comment)
        reason = get_field(changeset, :reason)

        changeset =
          if comment do
            add_error(changeset, :comment, "cannot be set for upvotes")
          else
            changeset
          end

        if reason do
          add_error(changeset, :reason, "cannot be set for upvotes")
        else
          changeset
        end

      _ ->
        changeset
    end
  end

  @doc """
  Returns the valid vote types.
  """
  def vote_types, do: @vote_types

  @doc """
  Returns the valid downvote reasons.
  """
  def downvote_reasons, do: @downvote_reasons
end
