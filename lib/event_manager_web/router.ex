defmodule EventManagerWeb.Router do
  use EventManagerWeb, :router
  import EventManagerWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {EventManagerWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", EventManagerWeb do
    pipe_through :browser

    get "/", PageController, :home
    get "/events", EventController, :index
    get "/events/:id", EventController, :show
    get "/certificates/verify", CertificateController, :verify

    # Auth routes
    get "/users/register", AuthController, :new_registration
    post "/users/register", AuthController, :create_registration
    get "/users/log_in", AuthController, :new_session
    post "/users/log_in", AuthController, :create_session
    get "/users/reset_password", AuthController, :new_reset_password
    post "/users/reset_password", AuthController, :create_reset_password
    get "/users/reset_password/:token", AuthController, :edit_reset_password
    put "/users/reset_password/:token", AuthController, :update_reset_password
  end

  scope "/", EventManagerWeb do
    pipe_through [:browser, :require_authenticated_user]

    get "/users/settings", AuthController, :edit_settings
    put "/users/settings", AuthController, :update_settings
    get "/users/settings/confirm_email/:token", AuthController, :confirm_email

    get "/my/certificates", CertificateController, :index
    get "/my/certificates/:id/download", CertificateController, :download
    get "/my/registrations", EventController, :my_registrations

    post "/events/:id/register", EventController, :register
    delete "/events/:id/register", EventController, :cancel_registration

    live_session :authenticated_user, on_mount: [{EventManagerWeb.UserAuth, :ensure_authenticated}] do
      live "/events/:id/chat", EventChatLive
      live "/events/:id/dashboard", EventDashboardLive
    end
