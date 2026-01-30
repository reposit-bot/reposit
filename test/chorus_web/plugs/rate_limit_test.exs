defmodule ChorusWeb.Plugs.RateLimitTest do
  use ChorusWeb.ConnCase, async: false

  alias ChorusWeb.Plugs.RateLimit

  describe "rate limit plug" do
    test "adds rate limit headers on allowed requests", %{conn: conn} do
      opts = RateLimit.init(action: :api)

      conn =
        conn
        |> Map.put(:remote_ip, {192, 168, 1, System.unique_integer([:positive])})
        |> RateLimit.call(opts)

      assert get_resp_header(conn, "x-ratelimit-limit") == ["100"]
      assert get_resp_header(conn, "x-ratelimit-remaining") == ["99"]
      assert [reset] = get_resp_header(conn, "x-ratelimit-reset")
      assert String.to_integer(reset) > System.system_time(:second)

      # Connection should not be halted
      refute conn.halted
    end

    test "respects X-Forwarded-For header", %{conn: conn} do
      opts = RateLimit.init(action: :api)

      conn =
        conn
        |> put_req_header("x-forwarded-for", "203.0.113.195, 70.41.3.18")
        |> RateLimit.call(opts)

      # Should use the first IP from X-Forwarded-For
      refute conn.halted
    end

    test "returns 429 when rate limit exceeded", %{conn: conn} do
      opts = RateLimit.init(action: :create_solution)
      ip = {10, 0, 0, System.unique_integer([:positive])}

      # Exhaust the limit (10 for create_solution)
      for _ <- 1..10 do
        conn
        |> Map.put(:remote_ip, ip)
        |> RateLimit.call(opts)
      end

      # Next request should be denied
      conn =
        conn
        |> Map.put(:remote_ip, ip)
        |> RateLimit.call(opts)

      assert conn.halted
      assert conn.status == 429
      assert get_resp_header(conn, "retry-after") != []

      body = Jason.decode!(conn.resp_body)
      assert body["success"] == false
      assert body["error"] == "rate_limit_exceeded"
      assert is_integer(body["retry_after"])
    end
  end
end
