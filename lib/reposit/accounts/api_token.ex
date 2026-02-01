defmodule Reposit.Accounts.ApiToken do
  @moduledoc """
  Schema for API tokens that enable programmatic access to Reposit.

  Each user can have multiple API tokens (up to 50), each with:
  - A user-friendly name for identification
  - A source indicating how the token was created (settings page or device flow)
  - Optional device name for tokens created via device flow
  - Last used timestamp for identifying stale tokens

  Tokens are stored as SHA256 hashes - the plaintext token is only shown once at creation.
  """
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  alias Reposit.Accounts.{ApiToken, User}

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  @hash_algorithm :sha256
  @rand_size 32
  @max_tokens_per_user 50

  @sources [:settings, :device_flow]

  schema "api_tokens" do
    field :token_hash, :binary, redact: true
    field :name, :string
    field :source, Ecto.Enum, values: @sources
    field :device_name, :string
    field :last_used_at, :utc_datetime

    belongs_to :user, User

    timestamps(type: :utc_datetime_usec)
  end

  @doc """
  Returns the maximum number of API tokens allowed per user.
  """
  def max_tokens_per_user, do: @max_tokens_per_user

  @doc """
  Generates a new API token.

  Returns `{plaintext_token, changeset}` where the plaintext token should be
  shown to the user once and never stored.

  ## Options
  - `device_name` - Optional device identifier for device_flow tokens

  ## Examples

      iex> {token, changeset} = ApiToken.generate(user, "My Laptop", :settings)
      iex> String.length(token)
      43
  """
  def generate(%User{} = user, name, source, opts \\ []) when source in @sources do
    device_name = Keyword.get(opts, :device_name)

    token = :crypto.strong_rand_bytes(@rand_size)
    encoded_token = Base.url_encode64(token, padding: false)
    hashed_token = :crypto.hash(@hash_algorithm, token)

    changeset =
      %ApiToken{}
      |> change()
      |> put_change(:token_hash, hashed_token)
      |> put_change(:name, name)
      |> put_change(:source, source)
      |> put_change(:device_name, device_name)
      |> put_change(:user_id, user.id)
      |> validate_required([:token_hash, :name, :source, :user_id])
      |> validate_length(:name, max: 255)
      |> validate_length(:device_name, max: 255)
      |> unique_constraint(:token_hash)
      |> foreign_key_constraint(:user_id)

    {encoded_token, changeset}
  end

  @doc """
  Verifies an API token and returns a query to find the associated user and token.

  Returns `{:ok, query}` where the query returns `{user, token}`, or `:error` if
  the token format is invalid.

  The query checks that the user is confirmed.
  """
  def verify_token_query(plaintext_token) do
    case Base.url_decode64(plaintext_token, padding: false) do
      {:ok, decoded_token} ->
        hashed_token = :crypto.hash(@hash_algorithm, decoded_token)

        query =
          from(t in ApiToken,
            join: u in assoc(t, :user),
            where: t.token_hash == ^hashed_token,
            where: not is_nil(u.confirmed_at),
            select: {u, t}
          )

        {:ok, query}

      :error ->
        :error
    end
  end

  @doc """
  Returns a query to list all API tokens for a user, ordered by most recent first.
  """
  def list_for_user_query(user_id) do
    from(t in ApiToken,
      where: t.user_id == ^user_id,
      order_by: [desc: t.inserted_at]
    )
  end

  @doc """
  Returns a query to count API tokens for a user.
  """
  def count_for_user_query(user_id) do
    from(t in ApiToken,
      where: t.user_id == ^user_id,
      select: count(t.id)
    )
  end

  @doc """
  Returns a query to find a specific token owned by a user.
  """
  def get_for_user_query(token_id, user_id) do
    from(t in ApiToken,
      where: t.id == ^token_id,
      where: t.user_id == ^user_id
    )
  end

  @doc """
  Returns a changeset for updating last_used_at timestamp.
  """
  def touch_changeset(%ApiToken{} = token) do
    change(token, last_used_at: DateTime.utc_now(:second))
  end

  @doc """
  Returns a changeset for updating the token name.
  """
  def rename_changeset(%ApiToken{} = token, new_name) do
    token
    |> change(name: new_name)
    |> validate_required([:name])
    |> validate_length(:name, max: 255)
  end
end
