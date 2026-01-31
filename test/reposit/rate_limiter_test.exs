defmodule Reposit.RateLimiterTest do
  use ExUnit.Case, async: false

  alias Reposit.RateLimiter

  describe "check_rate/2" do
    test "allows requests under the limit" do
      # Use unique IP to avoid interference
      ip = "test-#{System.unique_integer([:positive])}"

      assert {:allow, 1} = RateLimiter.check_rate(ip, :api)
      assert {:allow, 2} = RateLimiter.check_rate(ip, :api)
    end

    test "denies requests over the limit for create_solution" do
      # create_solution has limit of 10
      ip = "create-#{System.unique_integer([:positive])}"

      # Make 10 requests (all should be allowed)
      for i <- 1..10 do
        assert {:allow, ^i} = RateLimiter.check_rate(ip, :create_solution)
      end

      # 11th request should be denied
      assert {:deny, _retry_after} = RateLimiter.check_rate(ip, :create_solution)
    end

    test "different IPs have independent limits" do
      ip1 = "ip1-#{System.unique_integer([:positive])}"
      ip2 = "ip2-#{System.unique_integer([:positive])}"

      # Use up ip1's limit
      for _ <- 1..10 do
        RateLimiter.check_rate(ip1, :create_solution)
      end

      # ip2 should still be allowed
      assert {:allow, 1} = RateLimiter.check_rate(ip2, :create_solution)
    end

    test "different actions have independent limits" do
      ip = "actions-#{System.unique_integer([:positive])}"

      # Use up create_solution limit (10)
      for _ <- 1..10 do
        RateLimiter.check_rate(ip, :create_solution)
      end

      # api action should still work (has limit of 100)
      assert {:allow, 1} = RateLimiter.check_rate(ip, :api)
    end
  end

  describe "rate_limit_for/1" do
    test "returns correct limits for known actions" do
      assert {60_000, 100} = RateLimiter.rate_limit_for(:api)
      assert {60_000, 10} = RateLimiter.rate_limit_for(:create_solution)
      assert {60_000, 30} = RateLimiter.rate_limit_for(:vote)
    end

    test "returns default limit for unknown actions" do
      assert {60_000, 100} = RateLimiter.rate_limit_for(:unknown)
    end
  end
end
