defmodule Reposit.Votes.Vote do
  use Reposit.Schema

  @vote_types [:up, :down]
  @downvote_reasons [:incorrect, :outdated, :incomplete, :harmful, :duplicate, :other]

  schema "votes" do
    field(:vote_type, Ecto.Enum, values: @vote_types)
    field(:comment, :string)
    field(:reason, Ecto.Enum, values: @downvote_reasons)

    belongs_to(:solution, Reposit.Solutions.Solution)
    belongs_to(:user, Reposit.Accounts.User, type: :id)

    timestamps(type: :utc_datetime_usec, updated_at: false)
  end

  @required_fields [:solution_id, :user_id, :vote_type]
  @optional_fields [:comment, :reason]

  @doc """
  Changeset for creating a vote.

  Downvotes require a comment and reason. Upvotes cannot have comments or reasons.
  One vote per user per solution is enforced via database constraint.
  """
  def changeset(vote, attrs) do
    vote
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_inclusion(:vote_type, @vote_types)
    |> validate_downvote_requirements()
    |> validate_upvote_has_no_comment()
    |> foreign_key_constraint(:solution_id)
    |> foreign_key_constraint(:user_id)
    |> unique_constraint([:solution_id, :user_id],
      name: :votes_solution_id_user_id_unique,
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
