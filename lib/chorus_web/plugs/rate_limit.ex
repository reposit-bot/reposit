defmodule ChorusWeb.Plugs.RateLimit do
  @moduledoc """
  Plug for rate limiting API requests.

  Returns 429 Too Many Requests with Retry-After header when limit is exceeded.
  Includes X-RateLimit-* headers on all responses.
  """
  import Plug.Conn

  alias Chorus.RateLimiter

  @behaviour Plug

  @impl true
  def init(opts) do
    %{
      action: Keyword.get(opts, :action, :api)
    }
  end

  @impl true
  def call(conn, %{action: action}) do
    ip = get_client_ip(conn)

    case RateLimiter.check_rate(ip, action) do
      {:allow, count} ->
        add_rate_limit_headers(conn, action, count)

      {:deny, retry_after_ms} ->
        retry_after_seconds = div(retry_after_ms, 1000) + 1

        conn
        |> add_rate_limit_headers(action, :exceeded)
        |> put_resp_header("retry-after", to_string(retry_after_seconds))
        |> put_resp_content_type("application/json")
        |> send_resp(429, Jason.encode!(%{
          success: false,
          error: "rate_limit_exceeded",
          hint: "Too many requests. Please retry after #{retry_after_seconds} seconds.",
          retry_after: retry_after_seconds
        }))
        |> halt()
    end
  end

  defp get_client_ip(conn) do
    # Check X-Forwarded-For header first (for proxies/load balancers)
    forwarded_for = get_req_header(conn, "x-forwarded-for")

    case forwarded_for do
      [ips | _] ->
        # Take the first IP (original client)
        ips |> String.split(",") |> hd() |> String.trim()

      [] ->
        # Fall back to remote IP
        conn.remote_ip |> :inet.ntoa() |> to_string()
    end
  end

  defp add_rate_limit_headers(conn, action, count_or_status) do
    {_scale_ms, limit} = RateLimiter.rate_limit_for(action)

    remaining =
      case count_or_status do
        :exceeded -> 0
        count when is_integer(count) -> max(0, limit - count)
      end

    conn
    |> put_resp_header("x-ratelimit-limit", to_string(limit))
    |> put_resp_header("x-ratelimit-remaining", to_string(remaining))
    |> put_resp_header("x-ratelimit-reset", to_string(System.system_time(:second) + 60))
  end
end
