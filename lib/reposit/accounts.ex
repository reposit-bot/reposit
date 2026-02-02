defmodule Reposit.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias Reposit.Repo

  alias Reposit.Accounts.{DeviceCode, User, UserToken, UserNotifier}

  ## Database getters

  @doc """
  Gets a user by email.

  ## Examples

      iex> get_user_by_email("foo@example.com")
      %User{}

      iex> get_user_by_email("unknown@example.com")
      nil

  """
  def get_user_by_email(email) when is_binary(email) do
    Repo.get_by(User, email: email)
  end

  @doc """
  Gets a user by email and password.

  ## Examples

      iex> get_user_by_email_and_password("foo@example.com", "correct_password")
      %User{}

      iex> get_user_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_user_by_email_and_password(email, password)
      when is_binary(email) and is_binary(password) do
    user = Repo.get_by(User, email: email)
    if User.valid_password?(user, password), do: user
  end

  @doc """
  Gets a single user by ID.

  Returns `nil` if the user does not exist. Use for public profile lookups.

  ## Examples

      iex> get_user(123)
      %User{}

      iex> get_user(999)
      nil

  """
  def get_user(id), do: Repo.get(User, id)

  @doc """
  Gets a single user.

  Raises `Ecto.NoResultsError` if the User does not exist.

  ## Examples

      iex> get_user!(123)
      %User{}

      iex> get_user!(456)
      ** (Ecto.NoResultsError)

  """
  def get_user!(id), do: Repo.get!(User, id)

  @doc """
  Counts total users.
  """
  @spec count_users() :: non_neg_integer()
  def count_users do
    Repo.aggregate(User, :count)
  end

  ## User registration

  @doc """
  Registers a user.

  ## Examples

      iex> register_user(%{field: value})
      {:ok, %User{}}

      iex> register_user(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_user(attrs) do
    %User{}
    |> User.email_changeset(attrs)
    |> Repo.insert()
  end

  ## Settings

  @doc """
  Checks whether the user is in sudo mode.

  The user is in sudo mode when the last authentication was done no further
  than 60 minutes ago. The limit can be given as second argument in minutes.
  """
  def sudo_mode?(user, minutes \\ -60)

  def sudo_mode?(%User{authenticated_at: ts}, minutes) when is_struct(ts, DateTime) do
    DateTime.after?(ts, DateTime.utc_now() |> DateTime.add(minutes, :minute))
  end

  def sudo_mode?(_user, _minutes), do: false

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user email.

  See `Reposit.Accounts.User.email_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_email(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_email(user, attrs \\ %{}, opts \\ []) do
    User.email_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user email using the given token.

  If the token matches, the user email is updated and the token is deleted.
  """
  def update_user_email(user, token) do
    context = "change:#{user.email}"

    Repo.transact(fn ->
      with {:ok, query} <- UserToken.verify_change_email_token_query(token, context),
           %UserToken{sent_to: email} <- Repo.one(query),
           {:ok, user} <- Repo.update(User.email_changeset(user, %{email: email})),
           {_count, _result} <-
             Repo.delete_all(from(UserToken, where: [user_id: ^user.id, context: ^context])) do
        {:ok, user}
      else
        _ -> {:error, :transaction_aborted}
      end
    end)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user password.

  See `Reposit.Accounts.User.password_changeset/3` for a list of supported options.

  ## Examples

      iex> change_user_password(user)
      %Ecto.Changeset{data: %User{}}

  """
  def change_user_password(user, attrs \\ %{}, opts \\ []) do
    User.password_changeset(user, attrs, opts)
  end

  @doc """
  Updates the user password.

  Returns a tuple with the updated user, as well as a list of expired tokens.

  ## Examples

      iex> update_user_password(user, %{password: ...})
      {:ok, {%User{}, [...]}}

      iex> update_user_password(user, %{password: "too short"})
      {:error, %Ecto.Changeset{}}

  """
  def update_user_password(user, attrs) do
    user
    |> User.password_changeset(attrs)
    |> update_user_and_delete_all_tokens()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_user_session_token(user) do
    {token, user_token} = UserToken.build_session_token(user)
    Repo.insert!(user_token)
    token
  end

  @doc """
  Gets the user with the given signed token.

  If the token is valid `{user, token_inserted_at}` is returned, otherwise `nil` is returned.
  """
  def get_user_by_session_token(token) do
    {:ok, query} = UserToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Gets the user with the given magic link token.
  """
  def get_user_by_magic_link_token(token) do
    with {:ok, query} <- UserToken.verify_magic_link_token_query(token),
         {user, _token} <- Repo.one(query) do
      user
    else
      _ -> nil
    end
  end

  @doc """
  Logs the user in by magic link.

  There are three cases to consider:

  1. The user has already confirmed their email. They are logged in
     and the magic link is expired.

  2. The user has not confirmed their email and no password is set.
     In this case, the user gets confirmed, logged in, and all tokens -
     including session ones - are expired. In theory, no other tokens
     exist but we delete all of them for best security practices.

  3. The user has not confirmed their email but a password is set.
     This cannot happen in the default implementation but may be the
     source of security pitfalls. See the "Mixing magic link and password registration" section of
     `mix help phx.gen.auth`.
  """
  def login_user_by_magic_link(token) do
    {:ok, query} = UserToken.verify_magic_link_token_query(token)

    case Repo.one(query) do
      # Prevent session fixation attacks by disallowing magic links for unconfirmed users with password
      {%User{confirmed_at: nil, hashed_password: hash}, _token} when not is_nil(hash) ->
        raise """
        magic link log in is not allowed for unconfirmed users with a password set!

        This cannot happen with the default implementation, which indicates that you
        might have adapted the code to a different use case. Please make sure to read the
        "Mixing magic link and password registration" section of `mix help phx.gen.auth`.
        """

      {%User{confirmed_at: nil} = user, _token} ->
        user
        |> User.confirm_changeset()
        |> update_user_and_delete_all_tokens()

      {user, token} ->
        Repo.delete!(token)
        {:ok, {user, []}}

      nil ->
        {:error, :not_found}
    end
  end

  @doc ~S"""
  Delivers the update email instructions to the given user.

  ## Examples

      iex> deliver_user_update_email_instructions(user, current_email, &url(~p"/users/settings/confirm-email/#{&1}"))
      {:ok, %{to: ..., body: ...}}

  """
  def deliver_user_update_email_instructions(%User{} = user, current_email, update_email_url_fun)
      when is_function(update_email_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "change:#{current_email}")

    Repo.insert!(user_token)
    UserNotifier.deliver_update_email_instructions(user, update_email_url_fun.(encoded_token))
  end

  @doc """
  Delivers the magic link login instructions to the given user.
  """
  def deliver_login_instructions(%User{} = user, magic_link_url_fun)
      when is_function(magic_link_url_fun, 1) do
    {encoded_token, user_token} = UserToken.build_email_token(user, "login")
    Repo.insert!(user_token)
    UserNotifier.deliver_login_instructions(user, magic_link_url_fun.(encoded_token))
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_user_session_token(token) do
    Repo.delete_all(from(UserToken, where: [token: ^token, context: "session"]))
    :ok
  end

  ## Token helper

  defp update_user_and_delete_all_tokens(changeset) do
    Repo.transact(fn ->
      with {:ok, user} <- Repo.update(changeset) do
        tokens_to_expire = Repo.all_by(UserToken, user_id: user.id)

        Repo.delete_all(from(t in UserToken, where: t.id in ^Enum.map(tokens_to_expire, & &1.id)))

        {:ok, {user, tokens_to_expire}}
      end
    end)
  end

  ## Account Deletion

  @doc """
  Deletes a user and all associated data.

  This permanently removes the user account along with all their:
  - Session tokens
  - Solutions (contributions)
  - Votes

  The cascade delete is handled at the database level via foreign key constraints.

  ## Examples

      iex> delete_user(user)
      {:ok, %User{}}

  """
  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  ## API Tokens

  alias Reposit.Accounts.ApiToken

  @doc """
  Creates an API token for the user.

  Returns `{:ok, plaintext_token, api_token}` on success.
  The plaintext token should be shown to the user once and not stored.

  ## Options
  - `device_name` - Optional device identifier for device_flow tokens

  ## Examples

      iex> create_api_token(user, "My Laptop", :settings)
      {:ok, "abc123...", %ApiToken{}}

      iex> create_api_token(user, "CLI", :device_flow, device_name: "MacBook Pro")
      {:ok, "def456...", %ApiToken{}}
  """
  def create_api_token(%User{} = user, name, source, opts \\ []) do
    # Use a transaction with row locking to prevent race conditions
    # that could allow users to exceed the token limit
    Repo.transaction(fn ->
      # Lock the user row to serialize concurrent token creations
      from(u in User, where: u.id == ^user.id, lock: "FOR UPDATE")
      |> Repo.one!()

      if count_api_tokens(user) >= ApiToken.max_tokens_per_user() do
        Repo.rollback(:token_limit_reached)
      else
        {plaintext_token, changeset} = ApiToken.generate(user, name, source, opts)

        case Repo.insert(changeset) do
          {:ok, api_token} -> {plaintext_token, api_token}
          {:error, changeset} -> Repo.rollback(changeset)
        end
      end
    end)
    |> case do
      {:ok, {plaintext_token, api_token}} -> {:ok, plaintext_token, api_token}
      {:error, :token_limit_reached} -> {:error, :token_limit_reached}
      {:error, changeset} -> {:error, changeset}
    end
  end

  @doc """
  Lists all API tokens for a user.

  Returns token records with metadata (id, name, source, created, last_used).
  Does NOT return the actual token values.
  """
  def list_api_tokens(%User{} = user) do
    ApiToken.list_for_user_query(user.id)
    |> Repo.all()
  end

  @doc """
  Counts API tokens for a user.
  """
  def count_api_tokens(%User{} = user) do
    ApiToken.count_for_user_query(user.id)
    |> Repo.one()
  end

  @doc """
  Deletes an API token.

  Only allows deletion if the token belongs to the user.
  """
  def delete_api_token(%User{} = user, token_id) do
    ApiToken.get_for_user_query(token_id, user.id)
    |> Repo.delete_all()
    |> case do
      {1, _} -> {:ok, :deleted}
      {0, _} -> {:error, :not_found}
    end
  end

  @doc """
  Updates the name of an API token.
  """
  def rename_api_token(%User{} = user, token_id, new_name) do
    case Repo.one(ApiToken.get_for_user_query(token_id, user.id)) do
      nil ->
        {:error, :not_found}

      token ->
        token
        |> ApiToken.rename_changeset(new_name)
        |> Repo.update()
    end
  end

  @doc """
  Gets a user by their API token and updates last_used_at.

  Returns `nil` if the token is invalid or the user is not confirmed.
  """
  def get_user_by_api_token(token) when is_binary(token) do
    case ApiToken.verify_token_query(token) do
      {:ok, query} ->
        case Repo.one(query) do
          {user, api_token} ->
            # Update last_used_at. Async in prod/dev (non-blocking)
            if Application.get_env(:reposit, :api_token_touch_async, true) do
              Task.start(fn -> touch_api_token(api_token) end)
            else
              touch_api_token(api_token)
            end

            user

          nil ->
            nil
        end

      :error ->
        nil
    end
  end

  @doc """
  Updates the last_used_at timestamp for an API token.
  """
  def touch_api_token(%ApiToken{} = token) do
    token
    |> ApiToken.touch_changeset()
    |> Repo.update()
  end

  ## OAuth

  @doc """
  Gets or creates a user from Google OAuth.

  Handles three scenarios:
  1. User with this google_uid exists → return user
  2. User with this email exists → link Google account to existing user
  3. New user → create user with Google info

  In all cases, the user is auto-confirmed (Google already verified the email).
  """
  def get_or_create_user_from_google(%{email: email, uid: google_uid} = auth_info) do
    case Repo.get_by(User, google_uid: google_uid) do
      %User{} = user ->
        # User found by Google UID - return as-is (could update name/avatar here if desired)
        {:ok, user}

      nil ->
        # No user with this Google UID - check for email match
        case get_user_by_email(email) do
          %User{} = user ->
            # Link Google account to existing user and confirm
            link_google_and_confirm(user, auth_info)

          nil ->
            # Create new user with Google info
            create_user_from_google(auth_info)
        end
    end
  end

  defp oauth_name_for_existing_user(user, auth_info) do
    existing = user.name && String.trim(user.name)
    if existing != nil and existing != "", do: user.name, else: auth_info[:name]
  end

  defp link_google_and_confirm(user, auth_info) do
    attrs = %{
      google_uid: auth_info.uid,
      name: oauth_name_for_existing_user(user, auth_info),
      avatar_url: auth_info[:avatar_url] || user.avatar_url
    }

    changeset = User.link_google_changeset(user, attrs)

    # Also confirm user if not already confirmed
    changeset =
      if is_nil(user.confirmed_at) do
        Ecto.Changeset.put_change(changeset, :confirmed_at, DateTime.utc_now(:second))
      else
        changeset
      end

    Repo.update(changeset)
  end

  defp create_user_from_google(auth_info) do
    attrs = %{
      email: auth_info.email,
      google_uid: auth_info.uid,
      name: auth_info[:name],
      avatar_url: auth_info[:avatar_url]
    }

    %User{}
    |> User.google_oauth_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Gets or creates a user from GitHub OAuth.

  Handles three scenarios:
  1. User with this github_uid exists → return user
  2. User with this email exists → link GitHub account to existing user
  3. New user → create user with GitHub info

  In all cases, the user is auto-confirmed (GitHub already verified the email).
  """
  def get_or_create_user_from_github(%{email: email, uid: github_uid} = auth_info) do
    case Repo.get_by(User, github_uid: github_uid) do
      %User{} = user ->
        # User found by GitHub UID - return as-is
        {:ok, user}

      nil ->
        # No user with this GitHub UID - check for email match
        case get_user_by_email(email) do
          %User{} = user ->
            # Link GitHub account to existing user and confirm
            link_github_and_confirm(user, auth_info)

          nil ->
            # Create new user with GitHub info
            create_user_from_github(auth_info)
        end
    end
  end

  defp link_github_and_confirm(user, auth_info) do
    attrs = %{
      github_uid: auth_info.uid,
      name: oauth_name_for_existing_user(user, auth_info),
      avatar_url: auth_info[:avatar_url] || user.avatar_url
    }

    changeset = User.link_github_changeset(user, attrs)

    # Also confirm user if not already confirmed
    changeset =
      if is_nil(user.confirmed_at) do
        Ecto.Changeset.put_change(changeset, :confirmed_at, DateTime.utc_now(:second))
      else
        changeset
      end

    Repo.update(changeset)
  end

  defp create_user_from_github(auth_info) do
    attrs = %{
      email: auth_info.email,
      github_uid: auth_info.uid,
      name: auth_info[:name],
      avatar_url: auth_info[:avatar_url]
    }

    %User{}
    |> User.github_oauth_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Links a Google account to an existing logged-in user.

  Returns `{:ok, user}` or `{:error, changeset}`.
  """
  def link_google_account(%User{} = user, auth_info) do
    attrs = %{
      google_uid: auth_info.uid,
      name: oauth_name_for_existing_user(user, auth_info),
      avatar_url: auth_info[:avatar_url] || user.avatar_url
    }

    user
    |> User.link_google_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Links a GitHub account to an existing logged-in user.

  Returns `{:ok, user}` or `{:error, changeset}`.
  """
  def link_github_account(%User{} = user, auth_info) do
    attrs = %{
      github_uid: auth_info.uid,
      name: oauth_name_for_existing_user(user, auth_info),
      avatar_url: auth_info[:avatar_url] || user.avatar_url
    }

    user
    |> User.link_github_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Unlinks an OAuth provider from a user.

  Returns `{:ok, user}` or `{:error, changeset}`.
  """
  def unlink_oauth_provider(%User{} = user, provider) when provider in [:google, :github] do
    user
    |> User.unlink_oauth_changeset(provider)
    |> Repo.update()
  end

  @doc """
  Updates a user's profile (name).

  Returns `{:ok, user}` or `{:error, changeset}`.
  """
  def update_user_profile(%User{} = user, attrs) do
    user
    |> User.profile_changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for changing the user profile.
  """
  def change_user_profile(%User{} = user, attrs \\ %{}) do
    User.profile_changeset(user, attrs)
  end

  ## Device Code Flow

  @doc """
  Creates a new device code for CLI/MCP authentication.

  Returns `{:ok, device_code_info}` where device_code_info contains:
  - device_code: The code for the client to poll with
  - user_code: The code for the user to enter
  - verification_url: Where the user should go
  - expires_in: Seconds until expiration
  """
  def create_device_code(backend_url) do
    {device_code_string, user_code, device_code} = DeviceCode.build(backend_url)

    case Repo.insert(device_code) do
      {:ok, _record} ->
        {:ok,
         %{
           device_code: device_code_string,
           user_code: user_code,
           expires_in: DeviceCode.validity_in_minutes() * 60
         }}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  @doc """
  Polls for device code completion.

  ## Options
  - `device_name` - Name/identifier for the device (e.g., "MacBook Pro", "Claude Desktop")

  Returns:
  - `{:ok, :pending}` - User hasn't approved yet
  - `{:ok, token}` - User approved, here's their API token
  - `{:error, :expired}` - Code expired
  - `{:error, :not_found}` - Invalid code
  - `{:error, :token_limit_reached}` - User has too many tokens
  """
  def poll_device_code(device_code_string, opts \\ []) do
    device_name = Keyword.get(opts, :device_name)

    case DeviceCode.verify_device_code_query(device_code_string) do
      {:ok, query} ->
        # Use FOR UPDATE lock to prevent race conditions where multiple
        # concurrent polls could both see the same approved device code
        locked_query = from(q in query, lock: "FOR UPDATE")

        Repo.transaction(fn ->
          case Repo.one(locked_query) do
            nil ->
              Repo.rollback(:not_found)

            %DeviceCode{user_id: nil} ->
              Repo.rollback(:pending)

            %DeviceCode{user_id: user_id} = dc ->
              # User has approved - delete device code first (it's been "consumed"),
              # then generate API token. This prevents orphaned device codes.
              Repo.delete!(dc)

              user = get_user!(user_id)
              token_name = device_name || "Device Token"

              # Note: create_api_token has its own transaction which becomes
              # a nested operation within this transaction
              case create_api_token(user, token_name, :device_flow, device_name: device_name) do
                {:ok, token, _api_token} ->
                  token

                {:error, reason} ->
                  Repo.rollback(reason)
              end
          end
        end)
        |> case do
          {:ok, token} -> {:ok, token}
          {:error, :pending} -> {:ok, :pending}
          {:error, :not_found} -> {:error, :not_found}
          {:error, :token_limit_reached} -> {:error, :token_limit_reached}
          {:error, _} -> {:error, :token_generation_failed}
        end

      :error ->
        {:error, :not_found}
    end
  end

  @doc """
  Finds a pending device code by user code.
  """
  def get_device_code_by_user_code(user_code) do
    query = DeviceCode.by_user_code_query(user_code)
    Repo.one(query)
  end

  @doc """
  Approves a device code, linking it to the authenticated user.
  """
  def approve_device_code(%DeviceCode{} = device_code, %User{} = user) do
    device_code
    |> DeviceCode.approve_changeset(user)
    |> Repo.update()
  end

  @doc """
  Deletes expired device codes.
  """
  def delete_expired_device_codes do
    from(dc in DeviceCode, where: dc.expires_at < ^DateTime.utc_now())
    |> Repo.delete_all()
  end
end
