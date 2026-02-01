defmodule RepositWeb.Api.V1.DeviceAuthControllerTest do
  use RepositWeb.ConnCase, async: true

  import Reposit.AccountsFixtures

  alias Reposit.Accounts

  describe "POST /api/v1/auth/device" do
    test "creates device code and returns auth info", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/auth/device", %{})

      assert %{
               "success" => true,
               "data" => %{
                 "device_code" => device_code,
                 "user_code" => user_code,
                 "verification_url" => verification_url,
                 "expires_in" => expires_in,
                 "interval" => interval
               }
             } = json_response(conn, 200)

      assert is_binary(device_code)
      assert String.length(device_code) > 20
      assert String.match?(user_code, ~r/^[A-Z0-9]{4}-[A-Z0-9]{4}$/)
      assert verification_url =~ "/auth/device"
      assert expires_in == 900
      assert interval == 5
    end

    test "accepts custom backend_url", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/auth/device", %{backend_url: "https://custom.example.com"})

      assert %{"success" => true} = json_response(conn, 200)
    end
  end

  describe "POST /api/v1/auth/device/poll" do
    test "returns pending when user hasn't approved yet", %{conn: conn} do
      # Create a device code
      {:ok, %{device_code: device_code}} = Accounts.create_device_code("https://test.com")

      conn = post(conn, ~p"/api/v1/auth/device/poll", %{device_code: device_code})

      assert %{
               "success" => true,
               "data" => %{"status" => "pending"}
             } = json_response(conn, 200)
    end

    test "returns complete with token after user approves", %{conn: conn} do
      user = user_fixture()

      # Create and approve a device code
      {:ok, %{device_code: device_code, user_code: user_code}} =
        Accounts.create_device_code("https://test.com")

      # Approve the device code
      device_code_record = Accounts.get_device_code_by_user_code(user_code)
      {:ok, _} = Accounts.approve_device_code(device_code_record, user)

      conn = post(conn, ~p"/api/v1/auth/device/poll", %{device_code: device_code})

      assert %{
               "success" => true,
               "data" => %{
                 "status" => "complete",
                 "token" => token
               }
             } = json_response(conn, 200)

      assert is_binary(token)
      assert String.length(token) > 20

      # Verify the token works
      assert Accounts.get_user_by_api_token(token).id == user.id
    end

    test "creates token with device_name when provided", %{conn: conn} do
      user = user_fixture()

      # Create and approve a device code
      {:ok, %{device_code: device_code, user_code: user_code}} =
        Accounts.create_device_code("https://test.com")

      device_code_record = Accounts.get_device_code_by_user_code(user_code)
      {:ok, _} = Accounts.approve_device_code(device_code_record, user)

      conn =
        post(conn, ~p"/api/v1/auth/device/poll", %{
          device_code: device_code,
          device_name: "Claude Desktop"
        })

      assert %{
               "success" => true,
               "data" => %{"status" => "complete", "token" => token}
             } = json_response(conn, 200)

      # Verify token was created with correct metadata
      tokens = Accounts.list_api_tokens(user)
      assert length(tokens) == 1
      api_token = hd(tokens)
      assert api_token.name == "Claude Desktop"
      assert api_token.source == :device_flow
      assert api_token.device_name == "Claude Desktop"

      # Verify the token works
      assert Accounts.get_user_by_api_token(token).id == user.id
    end

    test "returns not_found for invalid device code", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/auth/device/poll", %{device_code: "invalid-code"})

      assert %{
               "success" => false,
               "error" => "not_found"
             } = json_response(conn, 404)
    end

    test "returns bad_request when device_code is missing", %{conn: conn} do
      conn = post(conn, ~p"/api/v1/auth/device/poll", %{})

      assert %{
               "success" => false,
               "error" => "missing_device_code"
             } = json_response(conn, 400)
    end
  end
end
