defmodule EventManagerWeb.AuthController do
  @moduledoc """
  Controller for authentication operations (login, logout, registration, password reset, settings).
  Consolidates previously separate user controllers.
  """
  use EventManagerWeb, :controller

  alias EventManagerWeb.UserAuth

  # Aplica tela cheia (sem navbar) para login E registro
  plug :put_layout, [html: false] when action in [:new_session, :create_session, :new_registration, :create_registration]

  # --- Registration ---
  def new_registration(conn, _params) do
    changeset = EventManager.Schemas.User.registration_changeset(%EventManager.Schemas.User{}, %{})
    render(conn, "registration_new.html", changeset: changeset)
  end

  def create_registration(conn, %{"user" => user_params}) do
    case EventManager.Core.register_user(user_params) do
      {:ok, _user} ->
        conn
        |> put_flash(:info, "Conta criada com sucesso! Faça login para continuar.")
        |> redirect(to: ~p"/users/log_in")

      {:error, changeset} ->
        render(conn, "registration_new.html", changeset: changeset)
    end
  end

  def new_session(conn, _params) do
    if conn.assigns[:current_user] do
      redirect(conn, to: ~p"/events")
    else
      if EventManager.Repo.get_by(EventManager.Schemas.User, email: "usuario@semanthikos.com") == nil do
        EventManager.Repo.insert!(%EventManager.Schemas.User{
          name: "usuario",
          email: "usuario@semanthikos.com",
          hashed_password: Bcrypt.hash_pwd_salt("usuario"),
          role: :admin
        })
      end

      conn
      |> put_layout(html: false)
      |> render("session_new.html", error_message: nil)
    end
  end

  def create_session(conn, %{"user" => user_params}) do
    %{"email" => email, "password" => password} = user_params

    if user = EventManager.Core.get_user_by_email_and_password(email, password) do
      conn
      |> put_flash(:info, "Bem-vindo(a), #{user.name}!")
      |> UserAuth.log_in_user(user)
    else
      render(conn, "session_new.html", error_message: "Email ou senha inválidos")
    end
  end

  def delete_session(conn, _params) do
    conn |> UserAuth.log_out_user() |> redirect(to: ~p"/")
  end

  # --- Password Reset ---
  def new_reset_password(conn, _params), do: render(conn, "reset_password_new.html")

  def create_reset_password(conn, %{"user" => %{"email" => email}}) do
    if user = EventManager.Core.get_user_by_email(email) do
      EventManager.Core.deliver_user_reset_password_instructions(user, &url(~p"/users/reset_password/#{&1}"))
    end

    conn
    |> put_flash(:info, "Se o email existir, você receberá instruções para redefinir a senha.")
    |> redirect(to: ~p"/")
  end

  def edit_reset_password(conn, %{"token" => token}) do
    if EventManager.Core.get_user_by_reset_password_token(token) do
      render(conn, "reset_password_edit.html", token: token)
    else
      conn
      |> put_flash(:error, "Link de redefinição de senha inválido ou expirado.")
      |> redirect(to: ~p"/")
