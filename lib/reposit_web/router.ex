defmodule RepositWeb.Router do
  use RepositWeb, :router

  import RepositWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {RepositWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug RepositWeb.Plugs.RateLimit, action: :api
  end

  pipeline :api_search do
    plug :accepts, ["json"]
    plug RepositWeb.Plugs.RateLimit, action: :search
  end

  pipeline :api_create do
    plug :accepts, ["json"]
    plug RepositWeb.Plugs.RateLimit, action: :create_solution
  end

  pipeline :api_vote do
    plug :accepts, ["json"]
    plug RepositWeb.Plugs.RateLimit, action: :vote
  end

  pipeline :api_auth do
    plug RepositWeb.Plugs.ApiAuth
  end

  scope "/", RepositWeb do
    pipe_through :browser

    live "/", HomeLive
    live "/demo", DemoLive
    live "/solutions", SolutionsLive.Index
    live "/solutions/:id", SolutionsLive.Show
    live "/search", SearchLive
    live "/moderation", ModerationLive
  end

  # API endpoints with rate limiting
  # Note: search route must be defined before :id to avoid matching "search" as an ID
  scope "/api/v1", RepositWeb.Api.V1 do
    pipe_through :api_search

    get "/solutions/search", SolutionsController, :search
  end

  scope "/api/v1", RepositWeb.Api.V1 do
    pipe_through :api

    get "/health", HealthController, :index
    get "/solutions/:id", SolutionsController, :show
  end

  scope "/api/v1", RepositWeb.Api.V1 do
    pipe_through [:api_create, :api_auth]

    post "/solutions", SolutionsController, :create
  end

  scope "/api/v1", RepositWeb.Api.V1 do
    pipe_through [:api_vote, :api_auth]

    post "/solutions/:solution_id/upvote", VotesController, :upvote
    post "/solutions/:solution_id/downvote", VotesController, :downvote
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:reposit, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: RepositWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  # Redirect old registration routes to sign-in
  scope "/" do
    pipe_through [:browser]

    get "/users/register", RepositWeb.Plugs.Redirect, to: "/users/log-in"
  end

  scope "/", RepositWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm-email/:token", UserSettingsController, :confirm_email
    post "/users/settings/regenerate-api-token", UserSettingsController, :regenerate_api_token
  end

  scope "/", RepositWeb do
    pipe_through [:browser]

    get "/users/log-in", UserSessionController, :new
    get "/users/log-in/:token", UserSessionController, :confirm
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end
