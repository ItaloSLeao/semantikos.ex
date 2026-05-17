defmodule EventManagerWeb.UserAuth do
  @moduledoc """
  Authentication and authorization plug for protecting routes.
  Implements role-based access control (RBAC).
  """
  use EventManagerWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  alias EventManager.Core
  alias EventManager.Schemas.User

  def fetch_current_user(conn, _opts) do
    {user_token, conn} = ensure_user_token(conn)
    user = if user_token, do: EventManager.Core.get_user_by_session_token(user_token), else: nil
    assign(conn, :current_user, user)
  end

  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "Você precisa estar logado para acessar esta página.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/users/log_in")
      |> halt()
    end
  end

  def require_admin(conn, _opts) do
    user = conn.assigns[:current_user]
    if user && User.admin?(user) do
      conn
    else
      conn |> put_flash(:error, "Acesso restrito a administradores.") |> redirect(to: ~p"/") |> halt()
    end
  end

  def require_speaker(conn, _opts) do
    user = conn.assigns[:current_user]
    if user && (User.admin?(user) || User.speaker?(user)) do
      conn
    else
      conn |> put_flash(:error, "Acesso restrito.") |> redirect(to: ~p"/") |> halt()
    end
  end

  defp ensure_user_token(conn) do
    if token = get_session(conn, :user_token) do
      {token, conn}
    else
      conn = fetch_cookies(conn, signed: ["user_token"])
      if token = conn.cookies["user_token"] do
        {token, put_session(conn, :user_token, token)}
      else
        {nil, conn}
      end
    end
  end

  @doc "Logs user in"
  def log_in_user(conn, user, params \\ %{}) do
    token = Core.generate_user_session_token(user)
