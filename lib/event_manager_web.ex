defmodule EventManagerWeb do
  @moduledoc """
  Web module that imports common functionality for controllers, views, and channels.
  """
  def controller do
    quote do
      use Phoenix.Controller,
        formats: [:html, :json],
        layouts: [html: EventManagerWeb.Layouts]

      import Plug.Conn
      import EventManagerWeb.Gettext

      unquote(verified_routes())
    end
  end

  def router do
    quote do
      use Phoenix.Router, helpers: false

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import EventManagerWeb.Gettext
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {EventManagerWeb.Layouts, :app}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent
