defmodule Reposit.Accounts.DeviceCodeTest do
  use Reposit.DataCase, async: true

  alias Reposit.Accounts.DeviceCode

  describe "build/1" do
    test "generates device code with correct format" do
      {device_code_string, user_code, device_code} = DeviceCode.build("https://test.com")

      # Device code should be base64 encoded
      assert is_binary(device_code_string)
      assert String.length(device_code_string) == 43
      assert {:ok, _} = Base.url_decode64(device_code_string, padding: false)

      # User code should be in XXXX-XXXX format with safe characters
      assert String.match?(user_code, ~r/^[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}$/)

      # Device code struct should have hashed device code
      assert is_binary(device_code.device_code)
      assert byte_size(device_code.device_code) == 32

      # Should have correct backend URL
      assert device_code.backend_url == "https://test.com"

      # Should expire in 15 minutes
      assert DateTime.diff(device_code.expires_at, DateTime.utc_now(), :minute) in 14..15

      # User should not be assigned yet
      assert is_nil(device_code.user_id)
    end

    test "generates unique user codes" do
      codes =
        1..100
        |> Enum.map(fn _ ->
          {_, user_code, _} = DeviceCode.build("https://test.com")
          user_code
        end)
        |> Enum.uniq()

      # All codes should be unique
      assert length(codes) == 100
    end
  end

  describe "verify_device_code_query/1" do
    test "returns query for valid device code" do
      {device_code_string, _, _} = DeviceCode.build("https://test.com")

      assert {:ok, query} = DeviceCode.verify_device_code_query(device_code_string)
      assert %Ecto.Query{} = query
    end

    test "returns error for invalid base64" do
      assert :error = DeviceCode.verify_device_code_query("not-valid-base64!!!")
    end
  end

  describe "by_user_code_query/1" do
    test "handles uppercase input" do
      query = DeviceCode.by_user_code_query("ABCD-1234")
      assert %Ecto.Query{} = query
    end

    test "handles lowercase input" do
      query = DeviceCode.by_user_code_query("abcd-1234")
      assert %Ecto.Query{} = query
    end

    test "handles input without dash" do
      query = DeviceCode.by_user_code_query("ABCD1234")
      assert %Ecto.Query{} = query
    end
  end

  describe "validity_in_minutes/0" do
    test "returns 15 minutes" do
      assert DeviceCode.validity_in_minutes() == 15
    end
  end
end
