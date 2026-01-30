defmodule ChorusWeb.Router do
  use ChorusWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {ChorusWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", ChorusWeb do
    pipe_through :browser

    get "/", PageController, :home
    live "/demo", DemoLive
    live "/solutions", SolutionsLive.Index
    live "/solutions/:id", SolutionsLive.Show
  end

  scope "/api/v1", ChorusWeb.Api.V1 do
    pipe_through :api

    get "/health", HealthController, :index

    # Search must come before resources to avoid matching as :id
    get "/solutions/search", SolutionsController, :search
    resources "/solutions", SolutionsController, only: [:create, :show]

    # Voting endpoints
    post "/solutions/:solution_id/upvote", VotesController, :upvote
    post "/solutions/:solution_id/downvote", VotesController, :downvote
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:chorus, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: ChorusWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
