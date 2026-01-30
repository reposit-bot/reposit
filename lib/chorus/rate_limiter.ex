defmodule Chorus.RateLimiter do
  @moduledoc """
  Rate limiter using Hammer with ETS backend.

  Default limits:
  - API requests: 100 per minute per IP
  - Solution creation: 10 per minute per IP
  - Voting: 30 per minute per IP
  """
  use Hammer, backend: :ets

  @doc """
  Checks if a request is allowed based on IP and action type.

  ## Actions and limits

  - `:api` - General API requests, 100/minute
  - `:create_solution` - Creating solutions, 10/minute
  - `:vote` - Voting on solutions, 30/minute

  ## Returns

  - `{:allow, count}` - Request allowed, count is current request count
  - `{:deny, retry_after}` - Rate limited, retry_after is milliseconds until reset
  """
  @spec check_rate(String.t(), atom()) :: {:allow, non_neg_integer()} | {:deny, non_neg_integer()}
  def check_rate(ip, action) do
    {scale_ms, limit} = rate_limit_for(action)
    key = "#{action}:#{ip}"

    hit(key, scale_ms, limit)
  end

  @doc """
  Returns the rate limit configuration for an action.

  Returns `{scale_ms, limit}` tuple.
  """
  @spec rate_limit_for(atom()) :: {non_neg_integer(), non_neg_integer()}
  def rate_limit_for(:api), do: {:timer.minutes(1), 100}
  def rate_limit_for(:create_solution), do: {:timer.minutes(1), 10}
  def rate_limit_for(:vote), do: {:timer.minutes(1), 30}
  def rate_limit_for(_), do: {:timer.minutes(1), 100}
end
