defmodule Chorus.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      ChorusWeb.Telemetry,
      Chorus.Repo,
      {DNSCluster, query: Application.get_env(:chorus, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Chorus.PubSub},
      # Rate limiter with ETS backend
      {Chorus.RateLimiter, clean_period: :timer.minutes(10)},
      # Start to serve requests, typically the last entry
      ChorusWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Chorus.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ChorusWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
