defmodule Reposit.AccountsTest do
  use Reposit.DataCase

  alias Reposit.Accounts

  import Reposit.AccountsFixtures
  alias Reposit.Accounts.{User, UserToken}

  describe "get_user_by_email/1" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email("unknown@example.com")
    end

    test "returns the user if the email exists" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user_by_email(user.email)
    end
  end

  describe "get_user_by_email_and_password/2" do
    test "does not return the user if the email does not exist" do
      refute Accounts.get_user_by_email_and_password("unknown@example.com", "hello world!")
    end

    test "does not return the user if the password is not valid" do
      user = user_fixture() |> set_password()
      refute Accounts.get_user_by_email_and_password(user.email, "invalid")
    end

    test "returns the user if the email and password are valid" do
      %{id: id} = user = user_fixture() |> set_password()

      assert %User{id: ^id} =
               Accounts.get_user_by_email_and_password(user.email, valid_user_password())
    end
  end

  describe "get_user!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_user!(-1)
      end
    end

    test "returns the user with the given id" do
      %{id: id} = user = user_fixture()
      assert %User{id: ^id} = Accounts.get_user!(user.id)
    end
  end

  describe "register_user/1" do
    test "requires email to be set" do
      {:error, changeset} = Accounts.register_user(%{})

      assert %{email: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates email when given" do
      {:error, changeset} = Accounts.register_user(%{email: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum values for email for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_user(%{email: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness" do
      %{email: email} = user_fixture()
      {:error, changeset} = Accounts.register_user(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the uppercased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_user(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers users without password" do
      email = unique_user_email()
      {:ok, user} = Accounts.register_user(valid_user_attributes(email: email))
      assert user.email == email
      assert is_nil(user.hashed_password)
      assert is_nil(user.confirmed_at)
      assert is_nil(user.password)
    end
  end

  describe "sudo_mode?/2" do
    test "validates the authenticated_at time" do
      now = DateTime.utc_now()

      assert Accounts.sudo_mode?(%User{authenticated_at: DateTime.utc_now()})
      assert Accounts.sudo_mode?(%User{authenticated_at: DateTime.add(now, -19, :minute)})
      refute Accounts.sudo_mode?(%User{authenticated_at: DateTime.add(now, -21, :minute)})

      # minute override
      refute Accounts.sudo_mode?(
               %User{authenticated_at: DateTime.add(now, -11, :minute)},
               -10
             )

      # not authenticated
      refute Accounts.sudo_mode?(%User{})
    end
  end

  describe "change_user_email/3" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_email(%User{})
      assert changeset.required == [:email]
    end
  end

  describe "deliver_user_update_email_instructions/3" do
    setup do
      %{user: user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(user, "current@example.com", url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "change:current@example.com"
    end
  end

  describe "update_user_email/2" do
    setup do
      user = unconfirmed_user_fixture()
      email = unique_user_email()

      token =
        extract_user_token(fn url ->
          Accounts.deliver_user_update_email_instructions(%{user | email: email}, user.email, url)
        end)

      %{user: user, token: token, email: email}
    end

    test "updates the email with a valid token", %{user: user, token: token, email: email} do
      assert {:ok, %{email: ^email}} = Accounts.update_user_email(user, token)
      changed_user = Repo.get!(User, user.id)
      assert changed_user.email != user.email
      assert changed_user.email == email
      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email with invalid token", %{user: user} do
      assert Accounts.update_user_email(user, "oops") ==
               {:error, :transaction_aborted}

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if user email changed", %{user: user, token: token} do
      assert Accounts.update_user_email(%{user | email: "current@example.com"}, token) ==
               {:error, :transaction_aborted}

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end

    test "does not update email if token expired", %{user: user, token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])

      assert Accounts.update_user_email(user, token) ==
               {:error, :transaction_aborted}

      assert Repo.get!(User, user.id).email == user.email
      assert Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "change_user_password/3" do
    test "returns a user changeset" do
      assert %Ecto.Changeset{} = changeset = Accounts.change_user_password(%User{})
      assert changeset.required == [:password]
    end

    test "allows fields to be set" do
      changeset =
        Accounts.change_user_password(
          %User{},
          %{
            "password" => "new valid password"
          },
          hash_password: false
        )

      assert changeset.valid?
      assert get_change(changeset, :password) == "new valid password"
      assert is_nil(get_change(changeset, :hashed_password))
    end
  end

  describe "update_user_password/2" do
    setup do
      %{user: user_fixture()}
    end

    test "validates password", %{user: user} do
      {:error, changeset} =
        Accounts.update_user_password(user, %{
          password: "not valid",
          password_confirmation: "another"
        })

      assert %{
               password: ["should be at least 12 character(s)"],
               password_confirmation: ["does not match password"]
             } = errors_on(changeset)
    end

    test "validates maximum values for password for security", %{user: user} do
      too_long = String.duplicate("db", 100)

      {:error, changeset} =
        Accounts.update_user_password(user, %{password: too_long})

      assert "should be at most 72 character(s)" in errors_on(changeset).password
    end

    test "updates the password", %{user: user} do
      {:ok, {user, expired_tokens}} =
        Accounts.update_user_password(user, %{
          password: "new valid password"
        })

      assert expired_tokens == []
      assert is_nil(user.password)
      assert Accounts.get_user_by_email_and_password(user.email, "new valid password")
    end

    test "deletes all tokens for the given user", %{user: user} do
      _ = Accounts.generate_user_session_token(user)

      {:ok, {_, _}} =
        Accounts.update_user_password(user, %{
          password: "new valid password"
        })

      refute Repo.get_by(UserToken, user_id: user.id)
    end
  end

  describe "generate_user_session_token/1" do
    setup do
      %{user: user_fixture()}
    end

    test "generates a token", %{user: user} do
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.context == "session"
      assert user_token.authenticated_at != nil

      # Creating the same token for another user should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%UserToken{
          token: user_token.token,
          user_id: user_fixture().id,
          context: "session"
        })
      end
    end

    test "duplicates the authenticated_at of given user in new token", %{user: user} do
      user = %{user | authenticated_at: DateTime.add(DateTime.utc_now(:second), -3600)}
      token = Accounts.generate_user_session_token(user)
      assert user_token = Repo.get_by(UserToken, token: token)
      assert user_token.authenticated_at == user.authenticated_at
      assert DateTime.compare(user_token.inserted_at, user.authenticated_at) == :gt
    end
  end

  describe "get_user_by_session_token/1" do
    setup do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      %{user: user, token: token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert {session_user, token_inserted_at} = Accounts.get_user_by_session_token(token)
      assert session_user.id == user.id
      assert session_user.authenticated_at != nil
      assert token_inserted_at != nil
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_session_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      dt = ~N[2020-01-01 00:00:00]
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: dt, authenticated_at: dt])
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "get_user_by_magic_link_token/1" do
    setup do
      user = user_fixture()
      {encoded_token, _hashed_token} = generate_user_magic_link_token(user)
      %{user: user, token: encoded_token}
    end

    test "returns user by token", %{user: user, token: token} do
      assert session_user = Accounts.get_user_by_magic_link_token(token)
      assert session_user.id == user.id
    end

    test "does not return user for invalid token" do
      refute Accounts.get_user_by_magic_link_token("oops")
    end

    test "does not return user for expired token", %{token: token} do
      {1, nil} = Repo.update_all(UserToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_user_by_magic_link_token(token)
    end
  end

  describe "login_user_by_magic_link/1" do
    test "confirms user and expires tokens" do
      user = unconfirmed_user_fixture()
      refute user.confirmed_at
      {encoded_token, hashed_token} = generate_user_magic_link_token(user)

      assert {:ok, {user, [%{token: ^hashed_token}]}} =
               Accounts.login_user_by_magic_link(encoded_token)

      assert user.confirmed_at
    end

    test "returns user and (deleted) token for confirmed user" do
      user = user_fixture()
      assert user.confirmed_at
      {encoded_token, _hashed_token} = generate_user_magic_link_token(user)
      assert {:ok, {^user, []}} = Accounts.login_user_by_magic_link(encoded_token)
      # one time use only
      assert {:error, :not_found} = Accounts.login_user_by_magic_link(encoded_token)
    end

    test "raises when unconfirmed user has password set" do
      user = unconfirmed_user_fixture()
      {1, nil} = Repo.update_all(User, set: [hashed_password: "hashed"])
      {encoded_token, _hashed_token} = generate_user_magic_link_token(user)

      assert_raise RuntimeError, ~r/magic link log in is not allowed/, fn ->
        Accounts.login_user_by_magic_link(encoded_token)
      end
    end
  end

  describe "delete_user_session_token/1" do
    test "deletes the token" do
      user = user_fixture()
      token = Accounts.generate_user_session_token(user)
      assert Accounts.delete_user_session_token(token) == :ok
      refute Accounts.get_user_by_session_token(token)
    end
  end

  describe "deliver_login_instructions/2" do
    setup do
      %{user: unconfirmed_user_fixture()}
    end

    test "sends token through notification", %{user: user} do
      token =
        extract_user_token(fn url ->
          Accounts.deliver_login_instructions(user, url)
        end)

      {:ok, token} = Base.url_decode64(token, padding: false)
      assert user_token = Repo.get_by(UserToken, token: :crypto.hash(:sha256, token))
      assert user_token.user_id == user.id
      assert user_token.sent_to == user.email
      assert user_token.context == "login"
    end
  end

  describe "inspect/2 for the User module" do
    test "does not include password" do
      refute inspect(%User{password: "123456"}) =~ "password: \"123456\""
    end
  end

  describe "get_user_by_api_token/1" do
    test "returns confirmed user with valid token" do
      user = user_fixture()
      {:ok, token, _api_token} = Accounts.create_api_token(user, "Test", :settings)

      assert found_user = Accounts.get_user_by_api_token(token)
      assert found_user.id == user.id
    end

    test "returns nil for invalid token" do
      refute Accounts.get_user_by_api_token("invalid")
    end

    test "returns nil for unconfirmed user" do
      user = unconfirmed_user_fixture()
      {:ok, token, _api_token} = Accounts.create_api_token(user, "Test", :settings)

      refute Accounts.get_user_by_api_token(token)
    end
  end

  describe "get_or_create_user_from_google/1" do
    test "creates new user when email doesn't exist" do
      auth_info = %{
        uid: "google_12345",
        email: "newuser@example.com",
        name: "New User",
        avatar_url: "https://example.com/avatar.jpg"
      }

      assert {:ok, user} = Accounts.get_or_create_user_from_google(auth_info)
      assert user.email == "newuser@example.com"
      assert user.google_uid == "google_12345"
      assert user.name == "New User"
      assert user.avatar_url == "https://example.com/avatar.jpg"
      assert user.confirmed_at != nil
    end

    test "links Google to existing user with same email" do
      existing_user = user_fixture()

      auth_info = %{
        uid: "google_12345",
        email: existing_user.email,
        name: "Google Name",
        avatar_url: "https://example.com/avatar.jpg"
      }

      assert {:ok, user} = Accounts.get_or_create_user_from_google(auth_info)
      assert user.id == existing_user.id
      assert user.google_uid == "google_12345"
    end

    test "returns existing user when google_uid already exists" do
      existing_user = user_with_google_fixture()

      auth_info = %{
        uid: existing_user.google_uid,
        email: "different@example.com",
        name: "Name",
        avatar_url: nil
      }

      assert {:ok, user} = Accounts.get_or_create_user_from_google(auth_info)
      assert user.id == existing_user.id
    end
  end

  describe "get_or_create_user_from_github/1" do
    test "creates new user when email doesn't exist" do
      auth_info = %{
        uid: 12345,
        email: "newuser@example.com",
        name: "New User",
        avatar_url: "https://example.com/avatar.jpg"
      }

      assert {:ok, user} = Accounts.get_or_create_user_from_github(auth_info)
      assert user.email == "newuser@example.com"
      assert user.github_uid == 12345
      assert user.name == "New User"
      assert user.avatar_url == "https://example.com/avatar.jpg"
      assert user.confirmed_at != nil
    end

    test "links GitHub to existing user with same email" do
      existing_user = user_fixture()

      auth_info = %{
        uid: 12345,
        email: existing_user.email,
        name: "GitHub Name",
        avatar_url: "https://example.com/avatar.jpg"
      }

      assert {:ok, user} = Accounts.get_or_create_user_from_github(auth_info)
      assert user.id == existing_user.id
      assert user.github_uid == 12345
    end

    test "returns existing user when github_uid already exists" do
      existing_user = user_with_github_fixture()

      auth_info = %{
        uid: existing_user.github_uid,
        email: "different@example.com",
        name: "Name",
        avatar_url: nil
      }

      assert {:ok, user} = Accounts.get_or_create_user_from_github(auth_info)
      assert user.id == existing_user.id
    end
  end

  describe "link_google_account/2" do
    test "links Google account to user" do
      user = user_fixture()

      auth_info = %{
        uid: "google_link_123",
        name: "Google Name",
        avatar_url: "https://example.com/avatar.jpg"
      }

      assert {:ok, updated_user} = Accounts.link_google_account(user, auth_info)
      assert updated_user.google_uid == "google_link_123"
    end

    test "fails if google_uid is already taken" do
      existing = user_with_google_fixture()
      user = user_fixture()

      auth_info = %{
        uid: existing.google_uid,
        name: nil,
        avatar_url: nil
      }

      assert {:error, changeset} = Accounts.link_google_account(user, auth_info)
      assert {"has already been taken", _} = changeset.errors[:google_uid]
    end
  end

  describe "link_github_account/2" do
    test "links GitHub account to user" do
      user = user_fixture()

      auth_info = %{
        uid: 456_789,
        name: "GitHub Name",
        avatar_url: "https://example.com/avatar.jpg"
      }

      assert {:ok, updated_user} = Accounts.link_github_account(user, auth_info)
      assert updated_user.github_uid == 456_789
    end

    test "fails if github_uid is already taken" do
      existing = user_with_github_fixture()
      user = user_fixture()

      auth_info = %{
        uid: existing.github_uid,
        name: nil,
        avatar_url: nil
      }

      assert {:error, changeset} = Accounts.link_github_account(user, auth_info)
      assert {"has already been taken", _} = changeset.errors[:github_uid]
    end
  end

  describe "unlink_oauth_provider/2" do
    test "unlinks Google account" do
      user = user_with_google_fixture()
      assert user.google_uid != nil

      assert {:ok, updated_user} = Accounts.unlink_oauth_provider(user, :google)
      assert updated_user.google_uid == nil
    end

    test "unlinks GitHub account" do
      user = user_with_github_fixture()
      assert user.github_uid != nil

      assert {:ok, updated_user} = Accounts.unlink_oauth_provider(user, :github)
      assert updated_user.github_uid == nil
    end
  end

  describe "update_user_profile/2" do
    test "updates user name" do
      user = user_fixture()

      assert {:ok, updated_user} = Accounts.update_user_profile(user, %{"name" => "New Name"})
      assert updated_user.name == "New Name"
    end

    test "allows empty name" do
      user = user_fixture()
      {:ok, user} = Accounts.update_user_profile(user, %{"name" => "Some Name"})

      assert {:ok, updated_user} = Accounts.update_user_profile(user, %{"name" => ""})
      # Empty string is cast to nil
      assert updated_user.name == nil
    end
  end

  describe "delete_user/1" do
    test "deletes the user" do
      user = user_fixture()
      assert {:ok, deleted_user} = Accounts.delete_user(user)
      assert deleted_user.id == user.id
      refute Repo.get(User, user.id)
    end

    test "cascades to delete user tokens" do
      user = user_fixture()
      _token = Accounts.generate_user_session_token(user)
      assert Repo.get_by(UserToken, user_id: user.id)

      {:ok, _} = Accounts.delete_user(user)

      refute Repo.get_by(UserToken, user_id: user.id)
    end

    test "cascades to delete user solutions" do
      user = user_fixture()
      scope = Reposit.Accounts.Scope.for_user(user)

      {:ok, solution} =
        Reposit.Solutions.create_solution(scope, %{
          problem: "Test problem description that is long enough for validation",
          solution:
            "Test solution pattern that is also long enough to pass the minimum character validation requirement"
        })

      {:ok, _} = Accounts.delete_user(user)

      refute Repo.get(Reposit.Solutions.Solution, solution.id)
    end

    test "cascades to delete user votes" do
      # Create solution author
      author = user_fixture(%{email: "author@example.com"})
      author_scope = Reposit.Accounts.Scope.for_user(author)

      {:ok, solution} =
        Reposit.Solutions.create_solution(author_scope, %{
          problem: "Test problem description that is long enough for validation",
          solution:
            "Test solution pattern that is also long enough to pass the minimum character validation requirement"
        })

      # Create voter
      voter = user_fixture(%{email: "voter@example.com"})
      voter_scope = Reposit.Accounts.Scope.for_user(voter)

      {:ok, vote} =
        Reposit.Votes.create_vote(voter_scope, %{
          solution_id: solution.id,
          vote_type: :up
        })

      # Delete the voter
      {:ok, _} = Accounts.delete_user(voter)

      # Vote should be deleted
      refute Repo.get(Reposit.Votes.Vote, vote.id)
      # Solution should still exist (owned by author)
      assert Repo.get(Reposit.Solutions.Solution, solution.id)
    end
  end
end
