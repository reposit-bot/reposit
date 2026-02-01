defmodule Reposit.AccountsApiTokensTest do
  use Reposit.DataCase, async: true

  alias Reposit.Accounts

  import Reposit.AccountsFixtures

  describe "create_api_token/4" do
    test "creates a token for the user" do
      user = user_fixture()

      assert {:ok, plaintext_token, api_token} =
               Accounts.create_api_token(user, "My Token", :settings)

      assert String.length(plaintext_token) == 43
      assert api_token.name == "My Token"
      assert api_token.source == :settings
      assert api_token.user_id == user.id
    end

    test "creates a device_flow token with device_name" do
      user = user_fixture()

      assert {:ok, _, api_token} =
               Accounts.create_api_token(user, "CLI Token", :device_flow,
                 device_name: "MacBook Pro"
               )

      assert api_token.source == :device_flow
      assert api_token.device_name == "MacBook Pro"
    end

    test "enforces 50 token limit" do
      user = user_fixture()

      # Create 50 tokens
      for i <- 1..50 do
        {:ok, _, _} = Accounts.create_api_token(user, "Token #{i}", :settings)
      end

      # 51st should fail
      assert {:error, :token_limit_reached} =
               Accounts.create_api_token(user, "Token 51", :settings)
    end
  end

  describe "list_api_tokens/1" do
    test "returns all tokens for user" do
      user = user_fixture()

      {:ok, _, _} = Accounts.create_api_token(user, "Token 1", :settings)

      {:ok, _, _} =
        Accounts.create_api_token(user, "Token 2", :device_flow, device_name: "Device")

      tokens = Accounts.list_api_tokens(user)
      assert length(tokens) == 2
    end

    test "returns empty list for user with no tokens" do
      user = user_fixture()
      assert [] = Accounts.list_api_tokens(user)
    end

    test "does not return other users' tokens" do
      user1 = user_fixture()
      user2 = user_fixture()

      {:ok, _, _} = Accounts.create_api_token(user1, "User1 Token", :settings)
      {:ok, _, _} = Accounts.create_api_token(user2, "User2 Token", :settings)

      tokens = Accounts.list_api_tokens(user1)
      assert length(tokens) == 1
      assert hd(tokens).name == "User1 Token"
    end
  end

  describe "count_api_tokens/1" do
    test "returns correct count" do
      user = user_fixture()

      assert Accounts.count_api_tokens(user) == 0

      {:ok, _, _} = Accounts.create_api_token(user, "Token 1", :settings)
      assert Accounts.count_api_tokens(user) == 1

      {:ok, _, _} = Accounts.create_api_token(user, "Token 2", :settings)
      assert Accounts.count_api_tokens(user) == 2
    end
  end

  describe "delete_api_token/2" do
    test "deletes the token" do
      user = user_fixture()
      {:ok, _, api_token} = Accounts.create_api_token(user, "To Delete", :settings)

      assert {:ok, :deleted} = Accounts.delete_api_token(user, api_token.id)
      assert Accounts.count_api_tokens(user) == 0
    end

    test "returns error for non-existent token" do
      user = user_fixture()
      assert {:error, :not_found} = Accounts.delete_api_token(user, 999_999)
    end

    test "cannot delete another user's token" do
      user1 = user_fixture()
      user2 = user_fixture()
      {:ok, _, api_token} = Accounts.create_api_token(user1, "User1 Token", :settings)

      assert {:error, :not_found} = Accounts.delete_api_token(user2, api_token.id)
      # Token still exists
      assert Accounts.count_api_tokens(user1) == 1
    end
  end

  describe "rename_api_token/3" do
    test "updates the token name" do
      user = user_fixture()
      {:ok, _, api_token} = Accounts.create_api_token(user, "Old Name", :settings)

      assert {:ok, updated} = Accounts.rename_api_token(user, api_token.id, "New Name")
      assert updated.name == "New Name"
    end

    test "returns error for non-existent token" do
      user = user_fixture()
      assert {:error, :not_found} = Accounts.rename_api_token(user, 999_999, "New Name")
    end

    test "cannot rename another user's token" do
      user1 = user_fixture()
      user2 = user_fixture()
      {:ok, _, api_token} = Accounts.create_api_token(user1, "User1 Token", :settings)

      assert {:error, :not_found} = Accounts.rename_api_token(user2, api_token.id, "Hijacked")
    end
  end

  describe "get_user_by_api_token/1" do
    test "returns user for valid new-style token" do
      user = user_fixture()
      {:ok, plaintext_token, _} = Accounts.create_api_token(user, "Test", :settings)

      found_user = Accounts.get_user_by_api_token(plaintext_token)
      assert found_user.id == user.id
    end

    test "returns nil for invalid token" do
      assert is_nil(Accounts.get_user_by_api_token("invalid-token"))
    end

    test "returns nil for non-existent token" do
      valid_but_nonexistent = "YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXoxMjM0NTY"
      assert is_nil(Accounts.get_user_by_api_token(valid_but_nonexistent))
    end

    test "returns nil for unconfirmed user's token" do
      user = unconfirmed_user_fixture()
      {:ok, plaintext_token, _} = Accounts.create_api_token(user, "Test", :settings)

      assert is_nil(Accounts.get_user_by_api_token(plaintext_token))
    end
  end

  describe "touch_api_token/1" do
    test "updates last_used_at" do
      user = user_fixture()
      {:ok, _, api_token} = Accounts.create_api_token(user, "Test", :settings)

      assert is_nil(api_token.last_used_at)

      {:ok, touched} = Accounts.touch_api_token(api_token)
      refute is_nil(touched.last_used_at)
    end
  end

  describe "poll_device_code/2 with device_name" do
    test "creates token with device_name" do
      user = user_fixture()

      # Create device code
      {:ok, device_code_info} = Accounts.create_device_code("https://test.com")

      # Approve it
      device_code = Accounts.get_device_code_by_user_code(device_code_info.user_code)
      {:ok, _} = Accounts.approve_device_code(device_code, user)

      # Poll with device_name
      {:ok, plaintext_token} =
        Accounts.poll_device_code(device_code_info.device_code, device_name: "Claude Desktop")

      # Verify the token was created with correct attributes
      tokens = Accounts.list_api_tokens(user)
      assert length(tokens) == 1
      token = hd(tokens)
      assert token.name == "Claude Desktop"
      assert token.source == :device_flow
      assert token.device_name == "Claude Desktop"

      # Verify the plaintext token works
      found_user = Accounts.get_user_by_api_token(plaintext_token)
      assert found_user.id == user.id
    end

    test "uses default name when device_name not provided" do
      user = user_fixture()

      {:ok, device_code_info} = Accounts.create_device_code("https://test.com")
      device_code = Accounts.get_device_code_by_user_code(device_code_info.user_code)
      {:ok, _} = Accounts.approve_device_code(device_code, user)

      {:ok, _} = Accounts.poll_device_code(device_code_info.device_code)

      tokens = Accounts.list_api_tokens(user)
      assert hd(tokens).name == "Device Token"
    end

    test "returns token_limit_reached and preserves device code for retry" do
      user = user_fixture()

      # Create 50 tokens to hit the limit
      for i <- 1..50 do
        {:ok, _, _} = Accounts.create_api_token(user, "Token #{i}", :settings)
      end

      # Create and approve device code
      {:ok, device_code_info} = Accounts.create_device_code("https://test.com")
      device_code = Accounts.get_device_code_by_user_code(device_code_info.user_code)
      {:ok, _} = Accounts.approve_device_code(device_code, user)

      # Poll should fail with token_limit_reached
      assert {:error, :token_limit_reached} =
               Accounts.poll_device_code(device_code_info.device_code, device_name: "My Device")

      # Device code should still be valid for retry after user deletes a token
      # (transaction rolled back, device code not deleted)
      # Polling again should still return token_limit_reached (code preserved)
      assert {:error, :token_limit_reached} =
               Accounts.poll_device_code(device_code_info.device_code, device_name: "My Device")

      # Delete a token and try again
      token = hd(Accounts.list_api_tokens(user))
      {:ok, :deleted} = Accounts.delete_api_token(user, token.id)

      # Now polling should succeed
      {:ok, plaintext_token} =
        Accounts.poll_device_code(device_code_info.device_code, device_name: "My Device")

      assert is_binary(plaintext_token)
      assert Accounts.count_api_tokens(user) == 50
    end
  end
end
