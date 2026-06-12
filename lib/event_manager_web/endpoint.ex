defmodule EventManagerWeb.Endpoint do
  
  
  @moduledoc """
  Phoenix endpoint configuration.
  Handles HTTP requests, WebSocket connections, and static file serving.
  """
  use Phoenix.Endpoint, otp_app: :event_manager

  # Serve static files
  plug Plug.Static,
    at: "/",
    from: :event_manager,
    gzip: false,
    only: ~w(assets fonts images favicon.ico robots.txt uploads)

  # Code reloading for development
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
    plug Phoenix.Ecto.CheckRepoStatus, otp_app: :event_manager
  end

  @session_options [
    store: :cookie,
    key: "_event_manager_key",
    signing_salt: "SigningSalt123",
