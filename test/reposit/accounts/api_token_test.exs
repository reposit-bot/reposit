defmodule Reposit.Accounts.ApiTokenTest do
  use Reposit.DataCase, async: true

  alias Reposit.Accounts.ApiToken

  import Reposit.AccountsFixtures

  describe "generate/4" do
    test "generates a token with correct format" do
      user = user_fixture()
      {plaintext_token, changeset} = ApiToken.generate(user, "My Token", :settings)

      assert String.length(plaintext_token) == 43
      assert changeset.valid?
      assert changeset.changes.name == "My Token"
      assert changeset.changes.source == :settings
      assert changeset.changes.user_id == user.id
      refute is_nil(changeset.changes.token_hash)
    end

    test "generates unique tokens each time" do
      user = user_fixture()
      {token1, _} = ApiToken.generate(user, "Token 1", :settings)
      {token2, _} = ApiToken.generate(user, "Token 2", :settings)

      refute token1 == token2
    end

    test "stores device_name for device_flow tokens" do
      user = user_fixture()
      {_, changeset} = ApiToken.generate(user, "My Device", :device_flow, device_name: "MacBook Pro")

      assert changeset.changes.device_name == "MacBook Pro"
      assert changeset.changes.source == :device_flow
    end

    test "validates name length" do
      user = user_fixture()
      long_name = String.duplicate("a", 256)
      {_, changeset} = ApiToken.generate(user, long_name, :settings)

      refute changeset.valid?
      assert {"should be at most %{count} character(s)", _} = changeset.errors[:name]
    end
  end

  describe "verify_token_query/1" do
    test "returns query for valid token" do
      user = user_fixture()
      {plaintext_token, changeset} = ApiToken.generate(user, "Test", :settings)
      {:ok, _api_token} = Repo.insert(changeset)

      assert {:ok, query} = ApiToken.verify_token_query(plaintext_token)
      assert {^user, _token} = Repo.one(query)
    end

    test "returns error for invalid base64" do
      assert :error = ApiToken.verify_token_query("not-valid-base64!!!")
    end

    test "returns nil for non-existent token" do
      assert {:ok, query} = ApiToken.verify_token_query("YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXoxMjM0NTY")
      assert is_nil(Repo.one(query))
    end

    test "does not return token for unconfirmed user" do
      user = unconfirmed_user_fixture()
      {plaintext_token, changeset} = ApiToken.generate(user, "Test", :settings)
      {:ok, _api_token} = Repo.insert(changeset)

      assert {:ok, query} = ApiToken.verify_token_query(plaintext_token)
      assert is_nil(Repo.one(query))
    end
  end

  describe "list_for_user_query/1" do
    test "returns tokens ordered by most recent first" do
      user = user_fixture()

      # Insert first token with an older timestamp
      {_, changeset1} = ApiToken.generate(user, "First", :settings)
      {:ok, token1} = Repo.insert(changeset1)

      # Manually set inserted_at to be older
      Repo.update_all(
        from(t in ApiToken, where: t.id == ^token1.id),
        set: [inserted_at: DateTime.add(DateTime.utc_now(:second), -60, :second)]
      )

      {_, changeset2} = ApiToken.generate(user, "Second", :settings)
      {:ok, _} = Repo.insert(changeset2)

      tokens = Repo.all(ApiToken.list_for_user_query(user.id))
      assert length(tokens) == 2
      assert hd(tokens).name == "Second"
    end

    test "only returns tokens for specified user" do
      user1 = user_fixture()
      user2 = user_fixture()

      {_, changeset1} = ApiToken.generate(user1, "User1 Token", :settings)
      {:ok, _} = Repo.insert(changeset1)

      {_, changeset2} = ApiToken.generate(user2, "User2 Token", :settings)
      {:ok, _} = Repo.insert(changeset2)

      tokens = Repo.all(ApiToken.list_for_user_query(user1.id))
      assert length(tokens) == 1
      assert hd(tokens).name == "User1 Token"
    end
  end

  describe "touch_changeset/1" do
    test "updates last_used_at to current time" do
      user = user_fixture()
      {_, changeset} = ApiToken.generate(user, "Test", :settings)
      {:ok, api_token} = Repo.insert(changeset)

      assert is_nil(api_token.last_used_at)

      touched = ApiToken.touch_changeset(api_token)
      assert touched.changes[:last_used_at]
    end
  end

  describe "rename_changeset/2" do
    test "updates the token name" do
      user = user_fixture()
      {_, changeset} = ApiToken.generate(user, "Old Name", :settings)
      {:ok, api_token} = Repo.insert(changeset)

      renamed = ApiToken.rename_changeset(api_token, "New Name")
      assert renamed.valid?
      assert renamed.changes.name == "New Name"
    end

    test "validates name is not empty" do
      user = user_fixture()
      {_, changeset} = ApiToken.generate(user, "Test", :settings)
      {:ok, api_token} = Repo.insert(changeset)

      renamed = ApiToken.rename_changeset(api_token, "")
      refute renamed.valid?
    end
  end
end
