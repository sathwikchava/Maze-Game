defmodule PhoenixmazeWeb.Router do
  use PhoenixmazeWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {PhoenixmazeWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PhoenixmazeWeb do
    pipe_through :browser

    # Change from PageController to GameLive
    live "/", GameLive  # Homepage with "Play" button
    live "/maze", MazeLive  # Maze page
  end

  # Development-only routes
  if Application.compile_env(:phoenixmaze, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live "/maze", PhoenixmazeWeb.MazeLive
      live_dashboard "/dashboard", metrics: PhoenixmazeWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
